# DuckDB.NativeBinaries

This repository contains a minimal C# project that packages the **native**
DuckDB shared libraries for all major platforms into a NuGet package.  The
package contains **no managed code**—it simply distributes the
`libduckdb.so`/`libduckdb.dylib`/`duckdb.dll` files for Linux, macOS and
Windows so they can be consumed by your own C# bindings.

DuckDB’s latest release (v1.3.2, published on 2025‑07‑08【542126742087475†L34-L41】) is the default target
version.  You can override this by setting the `DUCKDB_VERSION` environment
variable (e.g. `DUCKDB_VERSION=v1.4.0`) when running the fetch script.

## Files

- **DuckDB.NativeBinaries.csproj** – SDK‑style project file that defines
  package metadata and lists each native library in the appropriate
  runtime folder.  When you run `dotnet pack` this project, NuGet places
  each library into `runtimes/<rid>/native` so only the correct binary
  is copied to the consuming application【680930466352578†L640-L648】.
- **fetch_libs.sh** – Bash script that downloads the release artifacts
  from GitHub and extracts the shared libraries into the `runtimes`
  subdirectories.  Run this script before packing the project to ensure
  you have the latest binaries.
- **.github/workflows/auto-release.yml** – GitHub Actions workflow that
  periodically checks for new DuckDB releases.  If a new release is
  published, it updates the version in the project and script, fetches
  the new libraries, builds the NuGet package and pushes it to NuGet
  using a stored API key.  The workflow runs weekly but can also be
  triggered manually.

## Usage

1. Install the [.NET SDK](https://dotnet.microsoft.com/download) if you
   haven’t already.
2. Run `./fetch_libs.sh` from the `duckdb-native` directory.  The script
   downloads the current DuckDB release archives and places the
   appropriate shared library into each `runtimes` directory.
3. Build the NuGet package using:
   ```sh
   dotnet pack -c Release
   ```
   This generates `DuckDB.NativeBinaries.<version>.nupkg` in
   `bin/Release`.
4. Publish the package to NuGet (optional) using:
   ```sh
   dotnet nuget push bin/Release/DuckDB.NativeBinaries.<version>.nupkg \
     --api-key <YOUR_API_KEY> --source https://api.nuget.org/v3/index.json
   ```
   Replace `<YOUR_API_KEY>` with your NuGet.org API key.

## Automated updates

The GitHub Actions workflow (`auto-release.yml`) uses the GitHub API to
query the latest DuckDB release.  If a new tag is detected, it
automatically updates the version in `DuckDB.NativeBinaries.csproj` and
the default in `fetch_libs.sh`, runs the fetch script, commits the
updated files back to the repository and publishes the new NuGet package.
To enable publishing you must add a `NUGET_API_KEY` secret to your
repository and ensure the workflow has write access.