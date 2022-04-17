# This workflow uses actions that are not certified by GitHub.
# They are provided by a third-party and are governed by
# separate terms of service, privacy policy, and support
# documentation.

# This workflow integrates SecurityCodeScan with GitHub's Code Scanning feature
# SecurityCodeScan is a vulnerability patterns detector for C# and VB.NET

name: SecurityCodeScan

on:
  push:
    branches: [ main ]
  pull_request:
    # The branches below must be a subset of the branches above
    branches: [ main ]
  schedule:
    - cron: '16 21 * * 5'

jobs:
  SCS:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: nuget/setup-nuget@04b0c2b8d1b97922f67eca497d7cf0bf17b8ffe1
      - uses: microsoft/setup-msbuild@v1.0.2
      
      - name: Set up projects for analysis
        uses: security-code-scan/security-code-scan-add-action@f8ff4f2763ed6f229eded80b1f9af82ae7f32a0d
        
      - name: Restore dependencies	
        run: dotnet restore

      - name: Build
        run: dotnet build --no-restore

      - name: Convert sarif for uploading to GitHub
        uses: security-code-scan/security-code-scan-results-action@cdb3d5e639054395e45bf401cba8688fcaf7a687

      - name: Upload sarif
        uses: github/codeql-action/upload-sarif@v2
