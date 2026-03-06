# Security Audit Skills

## Idea

Use skills to perform interactive security audits.
The skill will detect vulnerabilities in a project by running various security tools and aggregating their findings.
The findings will be categorized by severity and type, providing a comprehensive overview of the project's security posture and trigger andon toward the security guild

## Roadmap

### 1. ✅ Initial audit skill for a single project
- Implement a skill that can run a set of predefined security tools (e.g., trivy, semgrep) on a project and aggregate the results into a structured format
- Focus on a single project to validate the concept and gather feedback

### 2. ✅ Support for multiple projects
- Extend the skill to support multiple projects, allowing users to choose their own tools and configurations

### 3. ✅  Baseline management and historical tracking
- Implement functionality to save baseline results and compare them with future scans to track improvements or regressions
- Generate a security score based on the findings and provide actionable insights for remediation (3S slide)

### 4. Tooling recommendations and integrations
- Based on the project's stack and previous findings, recommend additional tools or configurations to improve security coverage