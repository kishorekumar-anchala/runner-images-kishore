name: Failing Workflow
on:   # yamllint disable-line rule:truthy
  push: {}
  workflow_dispatch: {}
jobs:
  test:
    name: Checkout and Setup
    timeout-minutes: 5
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v4
    - name: Set up Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18.20.6'
