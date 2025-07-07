## Project TODOs

- **Generate an `env.json` configuration file**  
  Create a file named `env.json` containing pre-defined variables for configuring the environment on Windows 11.  
  Ensure every PowerShell (`.ps1`) script loads and uses this `env.json` for configuration.

- **Refactor `default.conf` to exclude user by default**  
  Update `default.conf` so it does **not** include the instance user by default.  
  Instead, capture the user internally within scripts and set