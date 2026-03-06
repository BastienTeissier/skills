# Django Access Inspector

## Overview

Django Access Inspector analyzes Django endpoint authentication and permission configurations. It detects unauthenticated endpoints, missing permission classes, and dangerous HTTP methods exposed without protection.

## Installation

```bash
pip install django-access-inspector
```

Then add `"django_access_inspector"` to `INSTALLED_APPS` in your Django settings.

## Verification

```bash
python manage.py inspect_access_control --help
```

If the command is not found, the package is not installed or `django_access_inspector` is not in `INSTALLED_APPS`.

## Scan Command

```bash
python manage.py inspect_access_control --output json > <output-dir>/django-access-inspector.json
```

For CI mode with snapshot comparison:

```bash
python manage.py inspect_access_control --ci --snapshot <snapshot.json> --output json > <output-dir>/django-access-inspector.json
```

## Output

- `<output-dir>/django-access-inspector.json` - JSON findings with authenticated, unauthenticated, unchecked, and admin endpoints

## Report Guidelines

After collecting the JSON output, perform the following analysis:

### Analyze the code

- For each unauthenticated or unchecked endpoint, identify the file containing the view function
- Read the file to understand the endpoint's logic
- Access other relevant files (models, serializers, etc.) as needed

### Interpret results

- Classify each endpoint's risk: critical, high, medium, low
- Identify missing or weak authentication / permission classes
- Spot dangerous HTTP methods (e.g., unauthenticated POST/PUT/DELETE)

### Generate advice

- Recommend concrete DRF/Django fixes (decorators, mixins, settings)
- Provide minimal working code snippets — only what is necessary
- Prioritize issues from highest to lowest severity
- If the output contains no unauthenticated or unchecked endpoints, report "No insecure endpoints found"

### Output format

Report findings in this structure:

- **Security Assessment**: one-sentence overall assessment
- **Critical Issues**: endpoints needing immediate attention or "None"
- **Recommendations**: specific code or config changes
- **Code Examples**: concise, runnable fix snippets
- **Best Practices**: broader advice for the project
