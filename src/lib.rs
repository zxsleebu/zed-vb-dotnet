//! VB.NET support for Zed.
//!
//! Highlighting, outline, indentation and so on are pure tree-sitter queries
//! (see `languages/vb-dotnet`). This crate only adds the language server.
//!
//! The server is [vb-ls](https://github.com/CoolCoderSuper/vb-ls): Microsoft's
//! Roslyn language server (the one behind the VS Code C# extension) with a
//! small patch that switches Visual Basic on. It needs a .NET 10 SDK, which it
//! uses (through MSBuild) to load `.sln` / `.vbproj` files.
//!
//! The server binary is resolved in this order:
//!   1. `lsp.vb-ls.binary.path` from the user's Zed settings;
//!   2. a `vb-ls` executable on PATH (`dotnet tool install -g vb-ls`);
//!   3. a pinned copy of the vb-ls NuGet package, downloaded into the
//!      extension's work directory and launched with `dotnet`.

use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;

use zed_extension_api::{
    self as zed,
    lsp::{Completion, CompletionKind, Symbol, SymbolKind},
    serde_json::{json, Map, Value},
    settings::LspSettings,
    CodeLabel, CodeLabelSpan, LanguageServerId, LanguageServerInstallationStatus, Result,
};

const SERVER_NAME: &str = "vb-ls";

/// Pinned vb-ls release. nuget.org package versions are immutable, so this is
/// always the exact build that was reviewed. Bump deliberately.
const VB_LS_VERSION: &str = "0.4.0";

/// Path of the Roslyn server inside the vb-ls `.nupkg` (a zip archive).
/// We start Roslyn directly with `dotnet` rather than going through the
/// package's `vb-ls.dll` shim, which only re-spawns this same file.
const SERVER_DLL_IN_PACKAGE: &str =
    "tools/net10.0/any/roslyn-lsp/Microsoft.CodeAnalysis.LanguageServer.dll";

const DOTNET_DOWNLOAD_URL: &str = "https://dotnet.microsoft.com/download/dotnet/10.0";

struct VbDotnetExtension {
    /// Absolute path of the downloaded server DLL, once verified to exist.
    cached_server_dll: Option<String>,
}

impl VbDotnetExtension {
    fn package_dir() -> String {
        format!("{SERVER_NAME}-{VB_LS_VERSION}")
    }

    /// Returns the absolute path to the Roslyn server DLL, downloading the
    /// pinned vb-ls package first if it is not already on disk.
    fn ensure_server_downloaded(&mut self, id: &LanguageServerId) -> Result<String> {
        if let Some(path) = &self.cached_server_dll {
            if fs::metadata(path).is_ok_and(|m| m.is_file()) {
                return Ok(path.clone());
            }
        }

        let package_dir = Self::package_dir();
        let relative_dll = format!("{package_dir}/{SERVER_DLL_IN_PACKAGE}");

        if !fs::metadata(&relative_dll).is_ok_and(|m| m.is_file()) {
            zed::set_language_server_installation_status(
                id,
                &LanguageServerInstallationStatus::Downloading,
            );

            // A half-extracted directory from an interrupted download would
            // otherwise make the existence check above pass next time.
            fs::remove_dir_all(&package_dir).ok();

            let url = format!(
                "https://api.nuget.org/v3-flatcontainer/{SERVER_NAME}/{VB_LS_VERSION}/{SERVER_NAME}.{VB_LS_VERSION}.nupkg"
            );
            if let Err(err) = zed::download_file(&url, &package_dir, zed::DownloadedFileType::Zip) {
                let message = format!("failed to download vb-ls {VB_LS_VERSION} from {url}: {err}");
                zed::set_language_server_installation_status(
                    id,
                    &LanguageServerInstallationStatus::Failed(message.clone()),
                );
                return Err(message);
            }

            if !fs::metadata(&relative_dll).is_ok_and(|m| m.is_file()) {
                let message = format!(
                    "downloaded vb-ls {VB_LS_VERSION} but {SERVER_DLL_IN_PACKAGE} is missing from the package"
                );
                zed::set_language_server_installation_status(
                    id,
                    &LanguageServerInstallationStatus::Failed(message.clone()),
                );
                return Err(message);
            }

            remove_stale_versions(&package_dir);
        }

        zed::set_language_server_installation_status(id, &LanguageServerInstallationStatus::None);

        let absolute = absolute_path(&relative_dll);
        self.cached_server_dll = Some(absolute.clone());
        Ok(absolute)
    }
}

/// Deletes `vb-ls-*` directories left behind by older pinned versions.
fn remove_stale_versions(keep: &str) {
    let Ok(entries) = fs::read_dir(".") else {
        return;
    };
    for entry in entries.flatten() {
        let name = entry.file_name();
        let Some(name) = name.to_str() else { continue };
        if name != keep && name.starts_with(&format!("{SERVER_NAME}-")) {
            fs::remove_dir_all(entry.path()).ok();
        }
    }
}

/// The extension runs with its work directory as CWD, but the server process
/// is spawned by Zed elsewhere, so every path handed to it must be absolute.
fn absolute_path(relative: &str) -> String {
    std::env::current_dir()
        .map(|cwd| cwd.join(relative))
        .unwrap_or_else(|_| PathBuf::from(relative))
        .to_string_lossy()
        .into_owned()
}

fn default_server_args() -> Vec<String> {
    vec![
        "--stdio".into(),
        // Without this Roslyn waits for a VS Code-only `solution/open`
        // notification and never loads anything. With it, Roslyn opens the
        // single .sln/.slnx at the worktree root, or else every
        // .vbproj/.csproj below it. With several solutions at the root, pick
        // one via `.vscode/settings.json` -> `"dotnet.defaultSolution"`.
        "--autoLoadProjects".into(),
        "--logLevel".into(),
        "Information".into(),
        "--extensionLogDirectory".into(),
        absolute_path("logs"),
    ]
}

/// Default Roslyn options, in the human-friendly nested form users also write
/// in `lsp.vb-ls.settings`. See [`flatten_roslyn_settings`] for the wire form.
fn default_settings() -> Value {
    json!({
        "inlay_hints": {
            "dotnet_enable_inlay_hints_for_parameters": true,
            "dotnet_enable_inlay_hints_for_literal_parameters": true,
            "dotnet_enable_inlay_hints_for_indexer_parameters": true,
            "dotnet_enable_inlay_hints_for_object_creation_parameters": true,
            "dotnet_enable_inlay_hints_for_other_parameters": false,
            "dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix": true,
            "dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent": true,
            "dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name": true
        },
        "completion": {
            "dotnet_show_completion_items_from_unimported_namespaces": true,
            "dotnet_show_name_completion_suggestions": true,
            "dotnet_provide_regex_completions": true,
            "dotnet_trigger_completion_in_argument_lists": true
        },
        "background_analysis": {
            // Compiler errors for the whole solution, so the project
            // diagnostics panel lists every broken file, not just open ones.
            "dotnet_compiler_diagnostics_scope": "FullSolution",
            // Analyzers are much more expensive; keep them to open files.
            "dotnet_analyzer_diagnostics_scope": "OpenFiles"
        },
        "symbol_search": {
            "dotnet_search_reference_assemblies": true
        },
        "navigation": {
            "dotnet_navigate_to_decompiled_sources": true,
            "dotnet_navigate_to_source_link_and_embedded_sources": true
        },
        "projects": {
            // Automatic restore asks the client to run `dotnet restore`
            // through a VS Code-only request that Zed does not implement.
            "dotnet_enable_automatic_restore": false
        }
    })
}

/// Recursively merges `overlay` into `base`; overlay wins on conflicts.
fn merge_json(base: &mut Value, overlay: Value) {
    match (base, overlay) {
        (Value::Object(base), Value::Object(overlay)) => {
            for (key, value) in overlay {
                merge_json(base.entry(key).or_insert(Value::Null), value);
            }
        }
        (base, overlay) => *base = overlay,
    }
}

/// Converts nested settings into the flat keys Roslyn asks for.
///
/// Roslyn requests options through `workspace/configuration` with sections
/// such as `visual_basic|inlay_hints.dotnet_enable_inlay_hints_for_parameters`
/// (per-language options) or `navigation.dotnet_navigate_to_decompiled_sources`
/// (global ones). Zed answers each section with a literal top-level key
/// lookup, without splitting on `.`, so nested JSON would never be found.
///
/// `{"inlay_hints": {"x": true}}` therefore becomes `inlay_hints.x`,
/// `visual_basic|inlay_hints.x` and `csharp|inlay_hints.x`. Keys the user
/// already wrote in flat or prefixed form are kept as they are.
fn flatten_roslyn_settings(settings: Value) -> Value {
    let mut flat = Map::new();
    let Value::Object(groups) = settings else {
        return Value::Object(flat);
    };

    let mut insert = |key: String, value: Value| {
        if key.contains('|') {
            flat.insert(key, value);
        } else {
            flat.insert(format!("visual_basic|{key}"), value.clone());
            flat.insert(format!("csharp|{key}"), value.clone());
            flat.insert(key, value);
        }
    };

    for (group, value) in groups {
        match value {
            Value::Object(options) if !group.contains('.') => {
                for (option, value) in options {
                    insert(format!("{group}.{option}"), value);
                }
            }
            value => insert(group, value),
        }
    }

    Value::Object(flat)
}

impl zed::Extension for VbDotnetExtension {
    fn new() -> Self {
        Self {
            cached_server_dll: None,
        }
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        let binary_settings = LspSettings::for_worktree(SERVER_NAME, worktree)
            .ok()
            .and_then(|settings| settings.binary);
        let user_args = binary_settings.as_ref().and_then(|b| b.arguments.clone());
        let user_env = binary_settings.as_ref().and_then(|b| b.env.clone());
        let user_path = binary_settings.and_then(|b| b.path);

        let mut env: HashMap<String, String> = worktree.shell_env().into_iter().collect();
        if let Some(user_env) = user_env {
            env.extend(user_env);
        }
        let env: Vec<(String, String)> = env.into_iter().collect();

        // 1. Explicit path from settings.
        if let Some(command) = user_path {
            return Ok(zed::Command {
                command,
                args: user_args.unwrap_or_else(default_server_args),
                env,
            });
        }

        // 2. A globally installed `dotnet tool install -g vb-ls`.
        if let Some(command) = worktree.which(SERVER_NAME) {
            return Ok(zed::Command {
                command,
                args: user_args.unwrap_or_else(default_server_args),
                env,
            });
        }

        // 3. Our own pinned download, run with the user's `dotnet`.
        let Some(dotnet) = worktree.which("dotnet") else {
            return Err(format!(
                "VB.NET language server: `dotnet` was not found on PATH. \
                 Install the .NET 10 SDK from {DOTNET_DOWNLOAD_URL} and restart Zed. \
                 (vb-ls is downloaded automatically after that; to manage it yourself \
                 run `dotnet tool install -g vb-ls`.)"
            ));
        };

        let server_dll = self.ensure_server_downloaded(language_server_id)?;
        let mut args = vec![server_dll];
        args.extend(user_args.unwrap_or_else(default_server_args));

        Ok(zed::Command {
            command: dotnet,
            args,
            env,
        })
    }

    fn language_server_initialization_options(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<Value>> {
        Ok(LspSettings::for_worktree(SERVER_NAME, worktree)
            .ok()
            .and_then(|settings| settings.initialization_options))
    }

    fn language_server_workspace_configuration(
        &mut self,
        _language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<Option<Value>> {
        let mut settings = default_settings();
        if let Some(user) = LspSettings::for_worktree(SERVER_NAME, worktree)
            .ok()
            .and_then(|settings| settings.settings)
        {
            merge_json(&mut settings, user);
        }
        Ok(Some(flatten_roslyn_settings(settings)))
    }

    fn label_for_completion(
        &self,
        _language_server_id: &LanguageServerId,
        completion: Completion,
    ) -> Option<CodeLabel> {
        let highlight = match completion.kind? {
            CompletionKind::Method | CompletionKind::Function | CompletionKind::Constructor => {
                "function"
            }
            CompletionKind::Class
            | CompletionKind::Interface
            | CompletionKind::Struct
            | CompletionKind::Module
            | CompletionKind::TypeParameter => "type",
            CompletionKind::Enum => "enum",
            CompletionKind::EnumMember => "variant",
            CompletionKind::Property | CompletionKind::Event => "property",
            CompletionKind::Field | CompletionKind::Variable => "variable",
            CompletionKind::Constant => "constant",
            CompletionKind::Keyword => "keyword",
            _ => return None,
        };

        let label = completion.label;
        let mut spans = vec![CodeLabelSpan::literal(label.clone(), Some(highlight.into()))];
        if let Some(detail) = completion
            .label_details
            .and_then(|details| details.detail)
            .filter(|detail| !detail.is_empty())
        {
            spans.push(CodeLabelSpan::literal(detail, None));
        }

        Some(CodeLabel {
            code: String::new(),
            spans,
            filter_range: (0..label.len()).into(),
        })
    }

    fn label_for_symbol(
        &self,
        _language_server_id: &LanguageServerId,
        symbol: Symbol,
    ) -> Option<CodeLabel> {
        let highlight = match symbol.kind {
            SymbolKind::Method | SymbolKind::Function | SymbolKind::Constructor => "function",
            SymbolKind::Class
            | SymbolKind::Interface
            | SymbolKind::Struct
            | SymbolKind::Module
            | SymbolKind::Namespace
            | SymbolKind::TypeParameter => "type",
            SymbolKind::Enum => "enum",
            SymbolKind::EnumMember => "variant",
            SymbolKind::Property | SymbolKind::Event => "property",
            SymbolKind::Field | SymbolKind::Variable => "variable",
            SymbolKind::Constant => "constant",
            _ => return None,
        };

        let name = symbol.name;
        Some(CodeLabel {
            code: String::new(),
            filter_range: (0..name.len()).into(),
            spans: vec![CodeLabelSpan::literal(name, Some(highlight.into()))],
        })
    }
}

zed::register_extension!(VbDotnetExtension);

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn flattens_nested_groups_for_both_languages() {
        let flat = flatten_roslyn_settings(json!({
            "inlay_hints": { "dotnet_enable_inlay_hints_for_parameters": true }
        }));
        for key in [
            "inlay_hints.dotnet_enable_inlay_hints_for_parameters",
            "visual_basic|inlay_hints.dotnet_enable_inlay_hints_for_parameters",
            "csharp|inlay_hints.dotnet_enable_inlay_hints_for_parameters",
        ] {
            assert_eq!(flat[key], json!(true), "missing {key}");
        }
    }

    #[test]
    fn keeps_already_flat_and_prefixed_keys() {
        let flat = flatten_roslyn_settings(json!({
            "visual_basic|completion.dotnet_show_name_completion_suggestions": false,
            "navigation.dotnet_navigate_to_decompiled_sources": false
        }));
        assert_eq!(
            flat["visual_basic|completion.dotnet_show_name_completion_suggestions"],
            json!(false)
        );
        assert!(flat
            .get("csharp|completion.dotnet_show_name_completion_suggestions")
            .is_none());
        assert_eq!(flat["navigation.dotnet_navigate_to_decompiled_sources"], json!(false));
        assert_eq!(
            flat["visual_basic|navigation.dotnet_navigate_to_decompiled_sources"],
            json!(false)
        );
    }

    #[test]
    fn user_settings_override_defaults() {
        let mut settings = default_settings();
        merge_json(
            &mut settings,
            json!({ "background_analysis": { "dotnet_analyzer_diagnostics_scope": "FullSolution" } }),
        );
        let flat = flatten_roslyn_settings(settings);
        assert_eq!(
            flat["background_analysis.dotnet_analyzer_diagnostics_scope"],
            json!("FullSolution")
        );
        // Untouched sibling defaults survive the merge.
        assert_eq!(
            flat["background_analysis.dotnet_compiler_diagnostics_scope"],
            json!("FullSolution")
        );
    }
}
