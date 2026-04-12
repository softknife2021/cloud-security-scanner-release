--
-- Minimal Seed Data for Kubernetes Deployment
-- Generated from pg_dump output, trimmed for ConfigMap (<1MB)
-- Contains: users, roles, projects, environments, project_environments,
--           scan_template, scan_preset, header_injection_presets,
--           api_payload, custom_script, license, flyway_schema_history
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users (id, created_at, updated_at, username, email, password, full_name, enabled, account_locked, last_login, version) VALUES (1, '2026-01-02 06:49:49.387', '2026-01-29 03:54:19.704', 'admin', 'admin@localhost', '$2a$10$.grjzh4ZC05E0VrVrLAbn.x9tAm5r.DSSuR8.4lTHbYjtEyASpsAm', 'Admin User', true, false, 1775058125135, 107);


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_roles (user_id, role, version) VALUES (1, 'VIEWER', 0);
INSERT INTO public.user_roles (user_id, role, version) VALUES (1, 'ADMIN', 0);
INSERT INTO public.user_roles (user_id, role, version) VALUES (1, 'ANALYST', 0);


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.projects (id, name, description, logo_url, is_active, created_at, updated_at, created_by, updated_by, version) VALUES (1, 'Default Project', 'Default project for existing environments', NULL, true, '2026-01-14 07:23:47.260807', '2026-01-14 07:23:47.260807', 'system', NULL, 0);


--
-- Data for Name: environments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.environments (id, name, description, is_active, created_at, updated_at, created_by, updated_by, auth_config, version, variables) VALUES (1, 'development', 'Development environment', true, '2026-01-09 18:28:31.591772', '2026-01-09 18:28:31.591772', 'system', NULL, '{}', 0, '[]');
INSERT INTO public.environments (id, name, description, is_active, created_at, updated_at, created_by, updated_by, auth_config, version, variables) VALUES (2, 'staging', 'Staging environment for pre-production testing', true, '2026-01-09 18:28:31.591772', '2026-01-09 18:28:31.591772', 'system', NULL, '{}', 0, '[]');
INSERT INTO public.environments (id, name, description, is_active, created_at, updated_at, created_by, updated_by, auth_config, version, variables) VALUES (3, 'production', 'Production environment', true, '2026-01-09 18:28:31.591772', '2026-01-09 18:28:31.591772', 'system', NULL, '{}', 0, '[]');


--
-- Data for Name: project_environments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_environments (project_id, environment_id, linked_at, linked_by) VALUES (1, 1, '2026-02-03 06:23:22.100619', NULL);
INSERT INTO public.project_environments (project_id, environment_id, linked_at, linked_by) VALUES (1, 2, '2026-02-03 06:23:22.100619', NULL);


--
-- Data for Name: scan_template; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (3, 'INFRASTRUCTURE', 'PORT_SCAN', 'NMAP', 'Nmap Aggressive Scan', 'Aggressive scan with OS detection and scripts', 'nmap -sT -A -T4 ${target} -p ${ports} -oX ${output_file}', 5400, 'XML', '2025-12-19 08:05:16.3901', '2025-12-19 08:05:16.3901', '{"parameters": [{"hint": "Format: Port ranges or comma-separated ports. Examples: ''80'' (single port), ''1-1000'' (range), ''80,443,8080'' (multiple ports), ''1-65535'' (all ports). Default: 1-1000", "name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Specify which ports to scan", "placeholder": "1-1000"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (33, 'INFRASTRUCTURE', 'VULNERABILITY_SCAN', 'TRIVY', 'Trivy Container Image Scan', 'Scan container images for OS packages, CVEs, misconfigurations, and secrets. Risk Level: LOW - Safe scanning.', 'trivy image --format json --output ${output_file} ${target}', 1800, 'JSON', '2025-12-28 04:14:56.856305', '2025-12-28 04:14:56.856305', '{"parameters": []}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (34, 'INFRASTRUCTURE', 'VULNERABILITY_SCAN', 'TRIVY', 'Trivy Filesystem Scan', 'Scan local filesystem for vulnerabilities in dependencies and configurations. Risk Level: LOW.', 'trivy fs --format json --output ${output_file} ${target}', 1200, 'JSON', '2025-12-28 04:14:56.856305', '2025-12-28 04:14:56.856305', '{"parameters": []}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (23, 'INFRASTRUCTURE', 'VULNERABILITY_SCAN', 'NMAP', 'NMAP Vulnerability Scan', 'Safe vulnerability detection using NSE vuln category. Checks for known CVEs and security issues. Risk Level: LOW - Safe for production.', 'nmap -sV --script vuln -oX ${output_file} ${target}', 3600, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "vuln", "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (25, 'INFRASTRUCTURE', 'SSL_TLS_AUDIT', 'NMAP', 'NMAP SSL/TLS Security Audit', 'Comprehensive SSL/TLS security analysis including cipher suites, certificates, and known SSL vulnerabilities. Risk Level: LOW - Safe.', 'nmap -sV --script ssl-enum-ciphers,ssl-cert,ssl-known-key -p 443 -oX ${output_file} ${target}', 1800, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "ssl-enum-ciphers,ssl-cert,ssl-known-key", "required": false}, {"hint": "Ports to scan", "name": "ports", "type": "text", "label": "Ports", "default": "443", "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (26, 'INFRASTRUCTURE', 'MALWARE_DETECTION', 'NMAP', 'NMAP Malware Detection', 'Check for malware infections, backdoors, and compromised services. Risk Level: LOW - Safe for production.', 'nmap --script malware -oX ${output_file} ${target}', 1800, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "malware", "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (28, 'INFRASTRUCTURE', 'INTRUSIVE_SCAN', 'NMAP', 'NMAP Intrusive Scan', '⚠️⚠️ EXTREME WARNING: Aggressive testing including vulnerability detection, exploitation attempts, and intrusive probes. Risk Level: VERY HIGH - May crash services, consume resources, trigger alerts. AUTHORIZED PENTESTING ONLY.', 'nmap -sV --script "vuln,exploit,intrusive" -oX ${output_file} ${target}', 7200, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "vuln,exploit,intrusive", "required": false}]}', 'CRITICAL', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (1, 'INFRASTRUCTURE', 'PORT_SCAN', 'NMAP', 'Nmap Quick Scan', 'Fast TCP SYN scan of top 1000 ports', 'nmap -sT -T4 ${target} --top-ports 1000 -oX ${output_file}', 3600, 'XML', '2025-12-19 08:05:16.3901', '2025-12-19 08:05:16.3901', '{"parameters": [{"hint": "Leave empty for top 1000 ports (default). Use 1-65535 for all ports.", "name": "ports", "type": "text", "label": "Port Range", "default": "", "required": false, "description": "Custom port range to scan", "placeholder": "1-1000, 22,80,443, or 1-65535"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping Check (-Pn)", "default": false, "required": false, "description": "Treat host as online without ping. Required for firewalled hosts that block ICMP.", "checkboxValue": "true"}, {"hint": "0=Paranoid (IDS evasion)  1=Sneaky  2=Polite  3=Normal  4=Aggressive (default)  5=Insane (may miss ports)", "name": "timing", "type": "text", "label": "Timing Template (0-5)", "default": "4", "required": false, "description": "Scan speed vs accuracy tradeoff"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (35, 'INFRASTRUCTURE', 'CONFIGURATION_SCAN', 'TRIVY', 'Trivy Configuration Scan', 'Scan IaC files (Dockerfile, K8s, Terraform) for security misconfigurations. Risk Level: LOW.', 'trivy config --format json --output ${output_file} ${target}', 600, 'JSON', '2025-12-28 04:14:56.856305', '2025-12-28 04:14:56.856305', '{"parameters": []}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (52, 'PERFORMANCE', 'STRESS_TEST', 'ARTILLERY', 'Artillery Stress Test', 'Stress test - 50 RPS for 60 seconds', 'artillery quick ${target} -c 50 -n 100 -o /tmp/report.json', 300, 'JSON', '2026-01-04 19:31:00.049033', '2026-01-04 19:31:00.049033', '{"vus": 50, "requests": 100}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (50, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Quick Load Test', 'Quick performance test - 5 RPS for 10 seconds', 'artillery quick ${target} -c 5 -n 10 -o /tmp/report.json', 300, 'JSON', '2026-01-04 19:31:00.049033', '2026-01-04 19:31:00.049033', '{"vus": 5, "requests": 10}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (53, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Ramp-up Load Test', 'Progressive load test that gradually increases traffic. Starts with 5 VUs/sec, ramps to 30 VUs/sec over 2 minutes. Good for finding performance degradation points.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Warm up", "rampTo": 15, "duration": 60, "arrivalRate": 5}, {"name": "Ramp to peak", "rampTo": 30, "duration": 60, "arrivalRate": 15}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (54, 'PERFORMANCE', 'STRESS_TEST', 'ARTILLERY', 'Artillery Spike Test', 'Simulates traffic spike - stable at 10 VUs/sec, then sudden burst to 100 VUs/sec for 30 seconds. Tests system resilience under sudden load.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Baseline", "duration": 30, "arrivalRate": 10}, {"name": "Spike", "duration": 30, "arrivalRate": 100}, {"name": "Recovery", "duration": 30, "arrivalRate": 10}], "maxVusers": 200}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (56, 'PERFORMANCE', 'ENDURANCE_TEST', 'ARTILLERY', 'Artillery Soak Test', 'Long-duration sustained load test at moderate traffic (10 VUs/sec for 10 minutes). Detects memory leaks, connection pool exhaustion, and gradual degradation.', 'artillery run ${config_file} -o ${output_file}', 900, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Sustained Load", "duration": 600, "arrivalRate": 10}], "maxVusers": 50}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (58, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Custom Phase Test', 'Fully customizable load test with multiple phases. User specifies phases array with duration, arrivalRate, rampTo, and optional maxVusers.', 'artillery run ${config_file} -o ${output_file}', 600, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Phase 1", "duration": 30, "arrivalRate": 5}, {"name": "Phase 2", "rampTo": 20, "duration": 60, "arrivalRate": 10}, {"name": "Phase 3", "duration": 30, "arrivalRate": 20}], "p95_threshold": 1000}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (59, 'KUBERNETES', 'vulnerability', 'TRIVY_K8S_MULTICONTEXT', 'Trivy Kubernetes Scanner', 'Scans Kubernetes clusters across multiple contexts using Trivy. Detects vulnerabilities, misconfigurations, and exposed secrets in workloads.', 'SCRIPT:TRIVY_K8S_MULTICONTEXT', 3600, 'JSON', '2026-01-07 03:16:44.983', '2026-01-07 07:40:07.448', '[{"hint": "Comma-separated namespaces to include (empty = all)", "name": "include_namespaces", "type": "text", "label": "Include Namespaces", "default": "", "required": false}, {"hint": "Namespaces to exclude from scan (comma-separated)", "name": "exclude_namespaces", "type": "text", "label": "Exclude Namespaces", "default": "kube-public,kube-system,kube-node-lease", "required": false}, {"name": "report_type", "type": "select", "label": "Report Type", "default": "summary", "options": ["summary", "all"], "required": false}, {"hint": "Number of concurrent namespace scans", "name": "parallel", "type": "number", "label": "Parallel Scans", "default": 2, "required": false}, {"hint": "Also run a cluster-wide scan", "name": "cluster_scan", "type": "boolean", "label": "Cluster-wide Scan", "default": false, "required": false}]', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (55, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery CI/CD Performance Gate', 'Performance test for CI/CD pipelines with SLO thresholds. Fails if P95 > 500ms or error rate > 1%. Returns non-zero exit code on threshold breach.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "duration": 60, "phaseName": "CI Performance Gate", "arrivalRate": 20, "maxErrorRate": 1, "p95_threshold": 500, "p99_threshold": 1000}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (57, 'PERFORMANCE', 'API_TEST', 'ARTILLERY', 'Artillery API POST Test', 'Load test for POST endpoints. Configurable method, headers (e.g., Authorization), and JSON body. Supports authenticated API testing.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"body": {"key": "value"}, "mode": "scenario", "path": "/api/endpoint", "method": "post", "headers": {"Content-Type": "application/json", "Authorization": "Bearer ${token}"}, "duration": 60, "arrivalRate": 10, "scenarioName": "API Test"}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (63, 'NETWORK', 'vulnerability', 'NMAP_VULN_CUSTOM', 'Nmap Vulnerability Scanner', 'Performs network vulnerability scanning using nmap with NSE vulnerability scripts', 'SCRIPT:NMAP_VULN_CUSTOM', 3600, 'JSON', '2026-01-07 06:23:59.936', '2026-01-07 06:23:59.936', '[{"name": "scan_type", "type": "select", "default": "standard", "options": ["quick", "standard", "deep"], "description": "Scan intensity level"}, {"name": "ports", "type": "string", "default": "1-1000", "description": "Port range to scan (e.g., 1-1000, 22,80,443)"}, {"name": "scripts", "type": "string", "default": "vuln", "description": "NSE script categories to run (e.g., vuln, default, safe)"}]', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (66, 'APPLICATION', 'vulnerability', 'NUCLEI_TEMPLATE_CUSTOM', 'Nuclei Template Scanner', 'Performs fast and customizable vulnerability scanning using nuclei templates', 'SCRIPT:NUCLEI_TEMPLATE_CUSTOM', 3600, 'JSON', '2026-01-07 06:25:28.748', '2026-01-07 06:25:28.748', '{"parameters": [{"name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high,medium,low", "required": false, "description": "Comma-separated severity levels", "placeholder": "critical,high,medium,low,info"}, {"name": "tags", "type": "text", "label": "Template Tags", "default": "", "required": false, "description": "Filter templates by tag", "placeholder": "cve,owasp,tech-detect"}, {"name": "exclude_tags", "type": "text", "label": "Exclude Tags", "default": "", "required": false, "description": "Exclude templates by tag", "placeholder": "dos,fuzz"}, {"name": "rate_limit", "type": "number", "label": "Rate Limit (req/sec)", "default": 150, "required": false, "description": "Maximum requests per second"}, {"name": "concurrency", "type": "number", "label": "Concurrency", "default": 25, "required": false, "description": "Number of concurrent template executions"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (65, 'APPLICATION', 'vulnerability', 'SQLMAP_INJECT_CUSTOM', 'SQLMap Injection Scanner', 'Performs automated SQL injection detection and exploitation testing using sqlmap', 'SCRIPT:SQLMAP_INJECT_CUSTOM', 3600, 'JSON', '2026-01-07 06:25:28.469', '2026-01-07 06:25:28.469', '{"parameters": [{"hint": "1=Safe 2=Moderate 3=Aggressive", "name": "risk", "type": "text", "label": "Risk Level (1-3)", "default": "1", "required": false, "description": "Risk of tests"}, {"hint": "1=Basic 2=Cookie 3=Headers 4=More 5=All", "name": "level", "type": "text", "label": "Test Level (1-5)", "default": "1", "required": false, "description": "Level of tests"}, {"name": "dbms", "type": "text", "label": "Target DBMS", "default": "", "required": false, "placeholder": "mysql, postgresql, mssql, oracle"}, {"hint": "B=Boolean E=Error U=Union S=Stacked T=Time Q=Inline", "name": "technique", "type": "text", "label": "Techniques (BEUSTQ)", "default": "", "required": false}, {"name": "threads", "type": "number", "label": "Threads", "default": 1, "required": false}, {"name": "forms", "type": "checkbox", "label": "Test Forms", "default": false, "required": false, "checkboxValue": "true"}, {"hint": "0=Disabled. Auto-discover injectable URLs.", "name": "crawl", "type": "text", "label": "Crawl Depth (0-5)", "default": "0", "required": false}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (70, 'API_SECURITY', 'SQL_INJECTION', 'API_SCANNER', 'API SQL Injection Test', 'Tests API endpoints for SQL injection vulnerabilities using predefined payloads', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "GET", "options": ["GET", "POST", "PUT", "PATCH", "DELETE"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "query", "options": ["query", "body", "path", "header"]}, {"hint": "Name of parameter to inject into", "name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded", "text/plain"]}, {"hint": "Optional Bearer token or Basic auth", "name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (71, 'API_SECURITY', 'XSS', 'API_SCANNER', 'API XSS Test', 'Tests API endpoints for Cross-Site Scripting vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "POST", "options": ["GET", "POST", "PUT", "PATCH"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "body", "options": ["query", "body", "header"]}, {"name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded"]}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (72, 'API_SECURITY', 'PATH_TRAVERSAL', 'API_SCANNER', 'API Path Traversal Test', 'Tests API endpoints for path traversal/LFI vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "GET", "options": ["GET", "POST"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "query", "options": ["query", "path"]}, {"hint": "File path parameter", "name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (73, 'API_SECURITY', 'COMMAND_INJECTION', 'API_SCANNER', 'API Command Injection Test', 'Tests API endpoints for OS command injection vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "POST", "options": ["GET", "POST"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "body", "options": ["query", "body"]}, {"name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded"]}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'CRITICAL', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (74, 'API_SECURITY', 'AUTH_BYPASS', 'API_SCANNER', 'API Authentication Bypass Test', 'Tests API authentication mechanisms for bypass vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "GET", "options": ["GET", "POST", "PUT", "DELETE"]}, {"hint": "Endpoint that requires auth", "name": "protected_endpoint", "type": "text", "label": "Protected Endpoint", "required": true}, {"hint": "Optional valid token to compare responses", "name": "valid_token", "type": "text", "label": "Valid Token"}]}', 'CRITICAL', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (75, 'API_SECURITY', 'FULL_SCAN', 'API_SCANNER', 'API Full Security Scan', 'Comprehensive API security test with all payload categories', 'INTERNAL:API_SCANNER', 900, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "POST", "options": ["GET", "POST", "PUT", "PATCH", "DELETE"]}, {"name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded"]}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}, {"hint": "Comma-separated list", "name": "categories", "type": "text", "label": "Payload Categories", "default": "SQL_INJECTION,XSS,PATH_TRAVERSAL"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (32, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei Web Technology Detection', 'Detect web technologies, frameworks, and potential misconfigurations. Risk Level: LOW - Information gathering.', 'nuclei -u ${target} -tags tech,misconfiguration -json-export ${output_file}', 900, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated template tags", "name": "tags", "type": "text", "label": "Template Tags", "default": "tech,misconfiguration", "required": false}, {"hint": "Max requests per second", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false}, {"hint": "Parallel executions", "name": "concurrency", "type": "number", "label": "Concurrency", "default": 25, "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (76, 'RECONNAISSANCE', 'DISCOVERY', 'WEB_CRAWLER', 'Web Crawler - Full Discovery', 'Multi-mode web crawler for site mapping, locator extraction, and validation. Modes: discovery (page objects/locators for Webdriver testing), validation (accessibility/security rules), extraction (URLs/params for security tools like SQLMap). Risk Level: LOW - Read-only scanning.', 'web_crawler ${target} --mode ${mode} --depth ${max_depth} --max-urls ${max_urls}', 1800, 'JSON', '2026-01-17 22:32:16.428518', '2026-01-17 22:32:16.428518', '{"parameters": [{"hint": "full=all modes, discovery=locators for testing, validation=rule checking, extraction=URLs for security tools", "name": "mode", "type": "select", "label": "Crawl Mode", "default": "full", "options": ["full", "discovery", "validation", "extraction"], "required": false}, {"hint": "How deep to follow links from the starting URL", "name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "2", "options": ["1", "2", "3", "4", "5"], "required": false}, {"hint": "Maximum number of pages to crawl", "name": "max_urls", "type": "select", "label": "Max URLs to Crawl", "default": "100", "options": ["25", "50", "100", "200"], "required": false}, {"hint": "Comma-separated rules: missing_alt,form_security,missing_meta,broken_links (empty=all)", "name": "rules", "type": "text", "label": "Validation Rules", "default": "", "required": false}, {"hint": "Regex patterns to exclude from crawl. Example: logout|admin|/api/", "name": "exclude_patterns", "type": "text", "label": "Exclude URL Patterns", "default": "", "required": false}, {"hint": "Delay between requests to avoid overwhelming the target", "name": "rate_limit", "type": "select", "label": "Request Delay (seconds)", "default": "0.5", "options": ["0.2", "0.5", "1.0", "2.0"], "required": false}, {"hint": "Extract form information for security testing", "name": "collect_forms", "type": "checkbox", "label": "Collect Form Data", "required": false, "checkboxValue": "true"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (77, 'RECONNAISSANCE', 'DISCOVERY', 'WEB_CRAWLER', 'Web Crawler - Page Object Discovery', 'Crawl website to discover page elements and build locator maps for automated testing (Webdriver/QReasp). Extracts inputs, buttons, forms, and links with semantic naming. Results can be exported for test automation.', 'web_crawler ${target} --mode discovery --depth ${max_depth}', 900, 'JSON', '2026-01-17 22:32:16.435186', '2026-01-17 22:32:16.435186', '{"parameters": [{"hint": "How deep to crawl (1=landing pages only, 2=one click deep, 3=two clicks deep)", "name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "2", "options": ["1", "2", "3"], "required": false}, {"name": "max_urls", "type": "select", "label": "Max Pages", "default": "50", "options": ["25", "50", "100"], "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (24, 'INFRASTRUCTURE', 'AUTHENTICATION_AUDIT', 'NMAP', 'NMAP Authentication Audit', 'Enumerate authentication methods and mechanisms. Tests SSH, HTTP, FTP, and other service authentication. Risk Level: LOW - Non-intrusive.', 'nmap -sV --script auth -oX ${output_file} ${target}', 1800, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "auth", "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (78, 'DATABASE', 'SQL_INJECTION_PREP', 'WEB_CRAWLER', 'Web Crawler - SQL Injection Targets', 'Crawl website to discover all URLs with query parameters and POST forms suitable for SQL injection testing. Use with SQLMap for comprehensive database security testing.', 'web_crawler ${target} --mode extraction --depth ${max_depth}', 600, 'JSON', '2026-01-17 22:32:16.436289', '2026-01-17 22:32:16.436289', '{"parameters": [{"hint": "Deeper crawl finds more injection points but takes longer", "name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "3", "options": ["1", "2", "3", "4", "5"], "required": false}, {"name": "max_urls", "type": "select", "label": "Max URLs", "default": "100", "options": ["50", "100", "200"], "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (79, 'WEB', 'COMPLIANCE_CHECK', 'WEB_CRAWLER', 'Web Crawler - Security & Accessibility Audit', 'Validate website against security and accessibility rules. Checks: missing alt text, forms without CSRF protection, password field security, missing meta tags, and more.', 'web_crawler ${target} --mode validation --depth ${max_depth}', 900, 'JSON', '2026-01-17 22:32:16.437459', '2026-01-17 22:32:16.437459', '{"parameters": [{"hint": "Leave empty for all rules, or specify: missing_alt,form_security,missing_meta", "name": "rules", "type": "text", "label": "Rules to Check", "default": "", "required": false}, {"name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "2", "options": ["1", "2", "3"], "required": false}, {"name": "max_urls", "type": "select", "label": "Max Pages", "default": "50", "options": ["25", "50", "100"], "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (36, 'NETWORK', 'discovery', 'NMAP', 'NSE Safe Discovery', 'Safe service and version discovery using default, safe, and version NSE scripts. Suitable for production environments.', 'nmap -sT -sV --script=default,safe,version -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.015144', '2026-01-02 06:19:48.015144', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (37, 'NETWORK', 'ssl_analysis', 'NMAP', 'SSL/TLS Certificate Analysis', 'Analyze SSL/TLS certificates and cipher suites. Identifies weak ciphers, expired certificates, and known vulnerabilities.', 'nmap -sT -sV --script=ssl-cert,ssl-enum-ciphers,ssl-known-key,ssl-date,ssl-heartbleed,ssl-poodle -p {{ports:443,8443,993,995,465}} -T{{timing:4}} -oX - {{target}}', 300, 'xml', '2026-01-02 06:19:48.018489', '2026-01-02 06:19:48.018489', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (4, 'DATABASE', 'SQL_INJECTION', 'SQLMAP', 'SQLMap Auto Scan', 'Automatic SQL injection detection and exploitation', 'sqlmap -u ${url} ${level} ${risk} ${threads} ${dbms} ${technique} ${dbs} ${tables} ${dump} --batch --output-dir=${output_dir}', 7200, 'JSON', '2025-12-19 08:05:16.394886', '2025-12-19 08:05:16.394886', '{"parameters": [{"hint": "Crawl site to discover ALL injectable URLs. Depth: 1=homepage only, 2=one click deep, 3+=deeper. Leave empty to test only the target URL.", "name": "crawl", "type": "select", "label": "Enable Site Crawling", "format": "--crawl={value}", "default": "", "options": ["", "1", "2", "3", "4", "5"], "required": false, "description": "Automatically discover and test all URLs with parameters"}, {"hint": "Also discover and report HTML forms (login forms, search boxes, etc). Requires crawl to be enabled.", "name": "forms", "type": "checkbox", "label": "Test Forms", "required": false, "description": "Include form discovery during crawl", "checkboxValue": "--forms"}, {"hint": "1=Basic (fastest), 2=Extended, 3=Good balance, 4=More thorough, 5=Maximum tests (slowest)", "name": "level", "type": "select", "label": "Detection Level", "format": "--level={value}", "default": "1", "options": ["1", "2", "3", "4", "5"], "required": false, "description": "Level of tests to perform (1-5)"}, {"hint": "1=Safe, 2=Medium (may cause data changes), 3=High (heavy queries). Use 1 for production.", "name": "risk", "type": "select", "label": "Risk Level", "format": "--risk={value}", "default": "1", "options": ["1", "2", "3"], "required": false, "description": "Risk of tests to perform (1-3)"}, {"hint": "Concurrent threads. Higher = faster but more load on target.", "name": "threads", "type": "select", "label": "Threads", "format": "--threads={value}", "default": "1", "options": ["1", "2", "3", "5", "10"], "required": false, "description": "Number of concurrent threads"}, {"hint": "Leave empty for auto-detection (recommended). SQLMap will fingerprint the database automatically.", "name": "dbms", "type": "select", "label": "Target DBMS", "format": "--dbms={value}", "default": "", "options": ["", "MySQL", "MariaDB", "PostgreSQL", "Microsoft SQL Server", "Oracle", "SQLite", "IBM DB2", "Firebird"], "required": false, "description": "Target database type. Only specify if you know the exact database."}, {"hint": "B=Boolean, E=Error, U=Union, S=Stacked, T=Time-based, Q=Inline. Default: BEUSTQ (all)", "name": "technique", "type": "text", "label": "Injection Techniques", "format": "--technique={value}", "default": "BEUSTQ", "required": false, "description": "SQL injection techniques to use"}, {"hint": "List all database names if injection is found", "name": "dbs", "type": "checkbox", "label": "Enumerate Databases", "required": false, "description": "Enumerate database names", "checkboxValue": "--dbs"}, {"hint": "List all table names if injection is found", "name": "tables", "type": "checkbox", "label": "Enumerate Tables", "required": false, "description": "Enumerate table names", "checkboxValue": "--tables"}, {"hint": "WARNING: Extract and save database contents. Only use on authorized test systems!", "name": "dump", "type": "checkbox", "label": "Dump Data", "required": false, "description": "Dump database table entries", "checkboxValue": "--dump"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (29, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei Full Vulnerability Scan', 'Comprehensive vulnerability scan using 9,000+ Nuclei templates. Checks for CVEs, misconfigurations, and security issues. Risk Level: LOW - Non-invasive testing.', 'nuclei -u ${target} -json-export ${output_file}', 1800, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated severity levels to include. Options: critical, high, medium, low, info. Example: critical,high (only critical and high findings)", "name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high,medium,low,info", "required": false, "description": "Filter templates by severity level"}, {"hint": "Comma-separated tags to filter templates. Examples: cve (known vulnerabilities), tech (technology detection), config (misconfigurations), xss, sqli, rce", "name": "tags", "type": "text", "label": "Template Tags", "required": false, "description": "Filter templates by tags (e.g., cve, tech, config)"}, {"hint": "Comma-separated tags to exclude. Example: dos,fuzz (skip DoS and fuzzing tests)", "name": "exclude_tags", "type": "text", "label": "Exclude Tags", "required": false, "description": "Exclude templates with these tags"}, {"hint": "Maximum requests per second. Lower values are safer but slower. Default: 150", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false, "description": "Maximum requests per second"}, {"hint": "Number of concurrent template executions. Default: 25", "name": "concurrency", "type": "number", "label": "Concurrency", "default": 25, "required": false, "description": "Number of parallel template executions"}, {"hint": "Timeout per request in seconds. Increase for slow targets. Default: 10", "name": "timeout", "type": "number", "label": "Request Timeout", "default": 10, "required": false, "description": "Timeout in seconds for each request"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (27, 'INFRASTRUCTURE', 'BRUTE_FORCE', 'NMAP', 'NMAP Brute Force Test', '⚠️ WARNING: Credential brute forcing across SSH, FTP, HTTP, MySQL, and other services. Risk Level: HIGH - May trigger alerts, lock accounts, and generate security events. AUTHORIZED USE ONLY.', 'nmap --script brute -oX ${output_file} ${target}', 7200, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "brute", "required": false}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (30, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei Critical & High Severity Scan', 'Focused scan for critical and high severity vulnerabilities only. Faster execution with prioritized findings. Risk Level: LOW.', 'nuclei -u ${target} -severity critical,high -json-export ${output_file}', 900, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated severity levels", "name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high", "required": false}, {"hint": "Filter by tags. Examples: cve, rce, sqli", "name": "tags", "type": "text", "label": "Template Tags", "required": false}, {"hint": "Tags to exclude", "name": "exclude_tags", "type": "text", "label": "Exclude Tags", "required": false}, {"hint": "Max requests per second", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (31, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei CVE Detection Scan', 'Targeted scan for known CVEs using Nuclei CVE templates. Risk Level: LOW - Passive detection only.', 'nuclei -u ${target} -tags cve -json-export ${output_file}', 1200, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated template tags", "name": "tags", "type": "text", "label": "Template Tags", "default": "cve", "required": false}, {"hint": "Filter CVEs by severity. Example: critical,high", "name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high,medium,low,info", "required": false}, {"hint": "Max requests per second", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false}, {"hint": "Timeout in seconds", "name": "timeout", "type": "number", "label": "Request Timeout", "default": 10, "required": false}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (88, 'WEB', 'UI_TEST', 'WEBDRIVER', 'WebDriver UI Test', 'Execute YAML-defined UI tests via Selenium WebDriver', 'webdriver-execute ${yaml_content}', 1800, 'JSON', '2026-01-24 07:37:25.188475', '2026-01-24 07:37:25.188475', '{"parameters": [{"name": "yamlContent", "type": "hidden"}, {"name": "pageObjects", "type": "hidden"}, {"name": "variables", "type": "hidden"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (51, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Medium Load Test', 'Medium load test - 20 RPS for 30 seconds', 'artillery quick ${target} -c 20 -n 50 -o /tmp/report.json', 300, 'JSON', '2026-01-04 19:31:00.049033', '2026-01-04 19:31:00.049033', '{"vus": 20, "requests": 50}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (64, 'WEB', 'vulnerability', 'NIKTO_WEB_CUSTOM', 'Nikto Web Vulnerability Scanner', 'Performs comprehensive web server vulnerability scanning using nikto', 'SCRIPT:NIKTO_WEB_CUSTOM', 3600, 'JSON', '2026-01-07 06:25:10.812', '2026-01-08 07:37:28.656', '{"parameters": [{"name": "port", "type": "text", "label": "Port", "default": "", "required": false, "description": "Target port number", "placeholder": "443, 8080"}, {"name": "ssl", "type": "checkbox", "label": "Force SSL/HTTPS", "default": false, "required": false, "description": "Force SSL connection", "checkboxValue": "true"}, {"hint": "1=Files 2=Misconfig 3=Info 4=XSS 5=File Retrieval 6=DoS 7=RCE 8=SQLi 9=Auth Bypass 0=Upload a=Auth b=Software c=Remote d=WebService e=Admin x=Reverse", "name": "tuning", "type": "text", "label": "Scan Tuning", "default": "", "required": false, "description": "Plugin selection tuning"}, {"name": "maxtime", "type": "number", "label": "Max Scan Time (seconds)", "default": "", "required": false, "description": "Maximum scan duration in seconds", "placeholder": "300"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (80, 'DATABASE', 'SQL_INJECTION', 'SQLMAP', 'SQLMap Site Discovery Scan', 'Automatically crawl a website to discover ALL pages with parameters, then test each for SQL injection. Best for comprehensive security assessments. The crawler will find login forms, search pages, and any URL with query parameters.', 'sqlmap -u ${url} ${crawl} ${forms} ${level} ${risk} ${threads} ${dbms} ${technique} ${dbs} ${tables} ${dump} --batch --output-dir=${output_dir}', 14400, 'JSON', '2026-01-17 22:48:31.03188', '2026-01-17 22:48:31.03188', '{"parameters": [{"hint": "1=Safe  2=Moderate (default for deep)  3=Aggressive", "name": "risk", "type": "text", "label": "Risk Level", "default": "2", "required": false, "description": "Risk of tests (1-3)"}, {"hint": "1=Basic  2=Cookie  3=Headers (default for deep)  4=More  5=All", "name": "level", "type": "text", "label": "Test Level", "default": "3", "required": false, "description": "Level of tests (1-5)"}, {"name": "dbms", "type": "text", "label": "Target DBMS", "default": "", "required": false, "description": "Force specific database type", "placeholder": "mysql, postgresql, mssql, oracle"}, {"hint": "B=Boolean E=Error U=Union S=Stacked T=Time Q=Inline", "name": "technique", "type": "text", "label": "Injection Techniques", "default": "", "required": false, "description": "Techniques to test (BEUSTQ)"}, {"name": "threads", "type": "number", "label": "Threads", "default": 3, "required": false, "description": "Concurrent threads"}, {"name": "forms", "type": "checkbox", "label": "Test Forms", "default": true, "required": false, "description": "Test HTML forms on the page", "checkboxValue": "true"}, {"hint": "0=Disabled  1-5=Depth. Discovers URLs with parameters automatically.", "name": "crawl", "type": "text", "label": "Crawl Depth", "default": "2", "required": false, "description": "Crawl the site to discover injectable pages (0-5)"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (2, 'INFRASTRUCTURE', 'PORT_SCAN', 'NMAP', 'Nmap Full TCP Scan', 'Comprehensive TCP scan with version detection', 'nmap -sT -sV -p- ${target} -oX ${output_file}', 7200, 'XML', '2025-12-19 08:05:16.3901', '2025-12-19 08:05:16.3901', '{"parameters": [{"name": "no_ping", "type": "checkbox", "label": "Skip Ping Check (-Pn)", "default": false, "required": false, "description": "Treat host as online without ping. Required for firewalled hosts.", "checkboxValue": "true"}, {"name": "os_detection", "type": "checkbox", "label": "OS Detection (-O)", "default": false, "required": false, "description": "Attempt to identify the operating system", "checkboxValue": "true"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing Template (0-5)", "default": "4", "required": false, "description": "Scan speed"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (38, 'NETWORK', 'vulnerability', 'NMAP', 'NSE Vulnerability Scan', 'Scan for known vulnerabilities using the vuln NSE category. Checks for CVEs and common misconfigurations.', 'nmap -sT -sV --script=vuln -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 900, 'xml', '2026-01-02 06:19:48.019345', '2026-01-02 06:19:48.019345', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (39, 'NETWORK', 'vulnerability', 'NMAP', 'Common Vulnerability Check', 'Check for common vulnerabilities including Heartbleed, EternalBlue, Shellshock, and SMB vulnerabilities.', 'nmap -sT -sV --script=ssl-heartbleed,smb-vuln-ms17-010,smb-vuln-ms08-067,http-shellshock,http-vuln-cve2017-5638 -p {{ports:21-25,80,139,443,445,8080}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.020191', '2026-01-02 06:19:48.020191', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (40, 'WEB', 'enumeration', 'NMAP', 'HTTP Service Enumeration', 'Enumerate HTTP services including titles, headers, methods, robots.txt, and sitemap.', 'nmap -sT -sV --script=http-title,http-headers,http-methods,http-robots.txt,http-sitemap-generator,http-server-header -p {{ports:80,443,8080,8443}} -T{{timing:4}} -oX - {{target}}', 300, 'xml', '2026-01-02 06:19:48.020997', '2026-01-02 06:19:48.020997', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (41, 'WEB', 'vulnerability', 'NMAP', 'HTTP Vulnerability Check', 'Check for HTTP-specific vulnerabilities including Shellshock, slowloris, and common web vulns.', 'nmap -sT -sV --script=http-vuln-*,http-shellshock,http-slowloris-check,http-sql-injection -p {{ports:80,443,8080,8443}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.021766', '2026-01-02 06:19:48.021766', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (43, 'DATABASE', 'discovery', 'NMAP', 'Database Service Discovery', 'Discover and enumerate database services (MySQL, PostgreSQL, MongoDB, Redis, MSSQL).', 'nmap -sT -sV --script=mysql-info,mysql-databases,pgsql-brute,mongodb-info,redis-info,ms-sql-info -p {{ports:3306,5432,27017,6379,1433,1521}} -T{{timing:4}} -oX - {{target}}', 300, 'xml', '2026-01-02 06:19:48.023287', '2026-01-02 06:19:48.023287', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (44, 'NETWORK', 'authentication', 'NMAP', 'Authentication Methods Check', 'Check authentication methods and look for weak authentication configurations.', 'nmap -sT -sV --script=auth,ssh-auth-methods,ftp-anon,http-auth,smtp-open-relay -p {{ports:21-25,22,80,110,143,443,993,995}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.024178', '2026-01-02 06:19:48.024178', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (45, 'INFRASTRUCTURE', 'malware', 'NMAP', 'Malware Indicator Detection', 'Check for known malware indicators and backdoors.', 'nmap -sT -sV --script=malware -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 900, 'xml', '2026-01-02 06:19:48.024954', '2026-01-02 06:19:48.024954', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (46, 'NETWORK', 'audit', 'NMAP', 'Comprehensive Security Audit', 'Full security audit using multiple NSE categories. May trigger security alerts. Use with caution.', 'nmap -sT -sV -O --script=default,safe,vuln,auth -p {{ports:1-65535}} -T{{timing:4}} -oX - {{target}}', 3600, 'xml', '2026-01-02 06:19:48.025766', '2026-01-02 06:19:48.025766', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (47, 'NETWORK', 'brute_force', 'NMAP', 'Credential Brute Force (AUTHORIZED ONLY)', 'Brute force credential testing. ONLY use with explicit authorization. May lock accounts.', 'nmap -sT -sV --script=brute -p {{ports:21,22,23,25,80,110,143,443,993,995,3306,5432}} -T{{timing:3}} -oX - {{target}}', 1800, 'xml', '2026-01-02 06:19:48.026553', '2026-01-02 06:19:48.026553', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (48, 'NETWORK', 'intrusive', 'NMAP', 'Intrusive Security Scan', 'Intrusive scanning that may trigger IDS/IPS alerts and consume target resources.', 'nmap -sT -sV --script=intrusive -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 1200, 'xml', '2026-01-02 06:19:48.027424', '2026-01-02 06:19:48.027424', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'HIGH', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (49, 'NETWORK', 'exploitation', 'NMAP', 'Exploitation Testing (PENTEST ONLY)', 'Attempt exploitation of known vulnerabilities. FOR AUTHORIZED PENETRATION TESTING ONLY. May crash services.', 'nmap -sT -sV --script=exploit -p {{ports:1-1000}} -T{{timing:3}} -oX - {{target}}', 1800, 'xml', '2026-01-02 06:19:48.028143', '2026-01-02 06:19:48.028143', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'CRITICAL', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (42, 'NETWORK', 'enumeration', 'NMAP', 'SMB Service Enumeration', 'Enumerate SMB shares, users, and check for SMB vulnerabilities including EternalBlue.', 'nmap -sT -sV --script=smb-enum-shares,smb-enum-users,smb-enum-sessions,smb-os-discovery,smb-security-mode,smb-vuln-* -p {{ports:139,445}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.022529', '2026-01-02 06:19:48.022529', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (22, 'WEB', 'VULNERABILITY_SCAN', 'ZAP', 'OWASP ZAP Security Scan', 'OWASP ZAP web application security scanner. Parameters: target (URL to scan, e.g., http://testphp.vulnweb.com), output_file (auto-generated), scan_type (optional: leave empty OR "quick" for passive scan [fastest, default], "full" for spider+active+passive scan [thorough but slow, 10-20 min], "api" for API-only passive scan), max_duration (optional: spider timeout in minutes, default 5, examples: 3, 10, 15)', '/usr/local/bin/zap-scan-wrapper.sh ${target} ${output_file} ${scan_type} ${max_duration}', 1800, 'JSON', '2025-12-26 23:34:13.477865', '2025-12-26 23:34:13.477865', '{"parameters": [{"hint": "Quick: passive checks only. Full: includes spidering and active attack scanning.", "name": "scan_type", "type": "select", "label": "Scan Type", "default": "quick", "options": [{"label": "Quick Scan (passive, ~5 min)", "value": "quick"}, {"label": "Full Scan (spider + active + AJAX, ~15-30 min)", "value": "full"}], "required": false, "description": "ZAP scan mode - quick is faster, full is more thorough"}]}', 'MEDIUM', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (21, 'WEB', 'WEB_SECURITY', 'NIKTO', 'Nikto Web Server Scan', 'Comprehensive web server scanner that tests for over 6700 potentially dangerous files/programs, outdated versions, and server configuration issues.', 'nikto -h ${target} ${port} ${ssl} ${tuning} ${plugins} ${maxtime} -o ${output_file} -Format txt', 1800, 'TEXT', '2025-12-26 04:37:32.545786', '2025-12-26 04:37:32.545786', '{"parameters": [{"hint": "Format: <number><unit> where unit is s (seconds), m (minutes), or h (hours). Examples: 5m, 10m, 30m", "name": "maxtime", "type": "text", "label": "Max Scan Time", "format": "-maxtime {value}", "default": "10m", "required": false, "description": "Maximum scan duration. Leave empty for no limit.", "placeholder": "10m"}, {"hint": "Enter a single port number between 1-65535", "name": "port", "type": "number", "label": "Port", "format": "-port {value}", "required": false, "description": "Target port (optional, default: 80 for HTTP, 443 for HTTPS)", "placeholder": "80"}, {"hint": "Check this box if the target uses HTTPS", "name": "ssl", "type": "checkbox", "label": "Use SSL/HTTPS", "required": false, "description": "Force SSL/HTTPS mode on the specified port", "checkboxValue": "-ssl"}, {"hint": "Format: Concatenated digits (NO commas, NO spaces). Examples: ''1'' (only Interesting Files), ''123'' (Files + Config + Info), ''4'' (only XSS/Injection). Options: 1=Files, 2=Config, 3=Info, 4=XSS/Injection, 5=RFI-WebRoot, 6=DoS, 7=RFI-ServerWide, 8=Cmd Exec, 9=SQL Injection, 0=File Upload, a=Auth Bypass, b=Software ID, c=Source Inclusion, x=Reverse (all EXCEPT specified)", "name": "tuning", "type": "text", "label": "Scan Tuning", "format": "-Tuning {value}", "required": false, "description": "Select which test categories to run (see options below)", "placeholder": "123"}, {"hint": "⚠️ LEAVE EMPTY (recommended) - Using @@ALL causes output truncation bug. Leave empty to use default plugins for complete results.", "name": "plugins", "type": "text", "label": "Plugins", "format": "-Plugins {value}", "default": "", "required": false, "description": "Specify which plugins to run (optional, advanced)", "placeholder": ""}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (81, 'MOBILE', 'MOBILE_UI_TEST', 'APPIUM', 'Appium Mobile Test', 'Execute mobile UI test via Appium', '', 600, 'JSON', '2026-02-08 02:41:10.438176', '2026-02-08 02:41:10.438176', '{"parameters": [{"name": "platform", "type": "select", "label": "Platform", "default": "ANDROID", "options": [{"label": "Android", "value": "ANDROID"}, {"label": "iOS", "value": "IOS"}], "required": true}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);
INSERT INTO public.scan_template (id, category, test_type, tool_name, name, description, command_template, timeout_seconds, output_format, created_at, updated_at, parameter_schema, risk_level, version, security_domain, scan_profile, estimated_duration_seconds, cwe_coverage, owasp_coverage) VALUES (82, 'MOBILE', 'MOBILE_INSPECTION', 'APPIUM_INSPECTOR', 'Appium Element Inspector', 'Discover mobile app elements via Appium', '', 300, 'JSON', '2026-02-08 02:41:10.445867', '2026-02-08 02:41:10.445867', '{"parameters": [{"name": "depth", "type": "number", "label": "Screen Depth", "default": 3, "required": false, "description": "How many screens deep to traverse"}]}', 'LOW', 0, NULL, 'STANDARD', NULL, NULL, NULL);


--
-- Data for Name: scan_preset; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (1, 'Quick Web Scan', 'Fast 60-second Nikto scan for quick assessments and development testing', 21, '${TARGET}', '{"maxtime":"-maxtime 60s","tuning":"-Tuning 1","plugins":"","port":"","ssl":""}', 'quick,web,dev', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 08:31:36.889076', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (3, 'Comprehensive Assessment', 'Thorough 5-minute security scan with extensive tuning for deep analysis', 21, '${TARGET}', '{"maxtime":"-maxtime 300s","tuning":"-Tuning 123456789","plugins":"","port":"","ssl":""}', 'comprehensive,thorough,monthly', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 08:31:36.889076', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (4, 'SSL/TLS Security Check', 'Focus on SSL/TLS configuration and HTTPS security', 21, '${TARGET}', '{"maxtime":"-maxtime 90s","tuning":"-Tuning 23","plugins":"","port":"","ssl":"-ssl"}', 'ssl,tls,https', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 08:31:36.889076', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (2, 'Standard Security Audit', 'Comprehensive Nikto scan with tuning 1234 for regular security assessments', 21, '${TARGET}', '{"maxtime":"-maxtime 120s","tuning":"-Tuning 1234","plugins":"","port":"","ssl":""}', 'standard,audit,production', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 23:00:22.073692', '2025-12-26 23:00:22.11', true, false, 1, 0);
INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (7, 'ZAP Baseline Scan', 'Quick passive ZAP scan (5 min spider + passive scan). Fast and non-intrusive.', 22, '${TARGET}', '{"scan_type":"","max_duration":"5"}', '{baseline,ci-cd,passive,quick}', 'security', 'system', '2025-12-26 23:37:18.941482', '2025-12-27 06:53:37.124149', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (8, 'ZAP Active Scan', 'Comprehensive ZAP scan with spider, active scan, and passive scan (30 min). Thorough but slow.', 22, '${TARGET}', '{"scan_type":"full","max_duration":"30"}', '{active,comprehensive,spider,thorough}', 'security', 'system', '2025-12-26 23:37:18.95124', '2025-12-27 06:53:37.132018', '2025-12-27 06:37:49.345', true, false, 1, 0);
INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (9, 'ZAP API Security Scan', 'ZAP API security scan (passive only, 15 min). Optimized for REST APIs.', 22, '${TARGET}', '{"scan_type":"api","max_duration":"15"}', '{api,rest,security,info-level}', 'api-security', 'system', '2025-12-26 23:37:18.956703', '2025-12-27 06:53:37.133634', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset (id, name, description, scan_template_id, target_pattern, parameters, tags, category, created_by, created_at, updated_at, last_used_at, is_public, is_favorite, execution_count, version) VALUES (10, 'ZAP Quick Scan', 'Ultra-fast ZAP baseline scan (3 min spider + passive). Good for quick checks.', 22, '${TARGET}', '{"scan_type":"","max_duration":"3"}', '{quick,fast,validation}', 'security', 'system', '2025-12-26 23:37:18.958363', '2026-01-21 09:26:44.721086', '2026-01-21 09:26:44.795', true, false, 1, 1);


--
-- Data for Name: header_injection_presets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.header_injection_presets (id, name, description, headers, is_system, is_active, created_at, updated_at, created_by, version) VALUES (1, 'Host Header Attack', 'Tests for Host header injection vulnerabilities. Can lead to cache poisoning, password reset poisoning, and SSRF.', '[{"payloads": ["evil.com", "localhost", "127.0.0.1", "internal.local"], "headerName": "Host", "description": "Host header override"}, {"payloads": ["evil.com", "attacker.com"], "headerName": "X-Forwarded-Host", "description": "Forwarded host spoofing"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets (id, name, description, headers, is_system, is_active, created_at, updated_at, created_by, version) VALUES (2, 'X-Forwarded Headers', 'Tests X-Forwarded-* headers for IP spoofing and trust bypass vulnerabilities.', '[{"payloads": ["127.0.0.1", "10.0.0.1", "192.168.1.1", "::1"], "headerName": "X-Forwarded-For", "description": "IP address spoofing"}, {"payloads": ["https", "http"], "headerName": "X-Forwarded-Proto", "description": "Protocol spoofing"}, {"payloads": ["127.0.0.1", "10.0.0.1"], "headerName": "X-Real-IP", "description": "Real IP override"}, {"payloads": ["127.0.0.1", "192.168.1.1"], "headerName": "X-Client-IP", "description": "Client IP spoofing"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets (id, name, description, headers, is_system, is_active, created_at, updated_at, created_by, version) VALUES (3, 'CRLF Injection', 'Tests for Carriage Return Line Feed injection in headers. Can lead to response splitting and header injection.', '[{"payloads": ["value\\r\\nX-Injected: true", "value\\r\\n\\r\\n<script>alert(1)</script>", "value%0d%0aX-Injected:%20true"], "headerName": "X-Custom-Header", "description": "CRLF injection attempts"}, {"payloads": ["Mozilla/5.0\\r\\nX-Injected: true"], "headerName": "User-Agent", "description": "User-Agent CRLF"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets (id, name, description, headers, is_system, is_active, created_at, updated_at, created_by, version) VALUES (4, 'Cache Poisoning', 'Tests headers that may affect caching behavior and lead to cache poisoning attacks.', '[{"payloads": ["evil.com", "attacker.com"], "headerName": "X-Forwarded-Host", "description": "Cache key poisoning via host"}, {"payloads": ["nothttps", "http"], "headerName": "X-Forwarded-Scheme", "description": "Scheme-based cache poisoning"}, {"payloads": ["/admin", "/internal/config"], "headerName": "X-Original-URL", "description": "URL override for cache"}, {"payloads": ["/admin", "/../admin"], "headerName": "X-Rewrite-URL", "description": "URL rewrite exploitation"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets (id, name, description, headers, is_system, is_active, created_at, updated_at, created_by, version) VALUES (5, 'Authentication Bypass Headers', 'Tests headers commonly used for authentication bypass in misconfigured proxies/load balancers.', '[{"payloads": ["/admin", "/api/admin", "/internal"], "headerName": "X-Original-URL", "description": "Original URL override"}, {"payloads": ["/admin", "/management"], "headerName": "X-Rewrite-URL", "description": "URL rewrite bypass"}, {"payloads": ["127.0.0.1"], "headerName": "X-Custom-IP-Authorization", "description": "Custom auth header"}, {"payloads": ["127.0.0.1", "::1"], "headerName": "X-Forwarded-For", "description": "Trusted IP bypass"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets (id, name, description, headers, is_system, is_active, created_at, updated_at, created_by, version) VALUES (6, 'Content Type Manipulation', 'Tests Content-Type header manipulation for parser differential attacks.', '[{"payloads": ["application/json", "application/xml", "text/xml", "application/x-www-form-urlencoded"], "headerName": "Content-Type", "description": "Content type switching"}, {"payloads": ["application/json", "text/html", "*/*"], "headerName": "Accept", "description": "Accept header manipulation"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);


--
-- Data for Name: api_payload; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (1, 'Basic OR Bypass', 'SQL_INJECTION', ''' OR ''1''=''1', 'Basic SQL injection OR bypass', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (2, 'OR 1=1', 'SQL_INJECTION', ''' OR 1=1--', 'Classic OR 1=1 injection', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (3, 'OR 1=1 Hash', 'SQL_INJECTION', ''' OR 1=1#', 'OR 1=1 with hash comment', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (4, 'Union Select', 'SQL_INJECTION', ''' UNION SELECT NULL--', 'Union-based injection probe', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (5, 'Union Select Multiple', 'SQL_INJECTION', ''' UNION SELECT NULL,NULL,NULL--', 'Union with multiple columns', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (6, 'Time-based Blind', 'SQL_INJECTION', ''' OR SLEEP(5)--', 'Time-based blind SQLi', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (7, 'Error-based', 'SQL_INJECTION', ''' AND 1=CONVERT(int,(SELECT @@version))--', 'Error-based SQLi for MSSQL', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (8, 'Stacked Query', 'SQL_INJECTION', '''; DROP TABLE users--', 'Stacked query injection', 'CRITICAL', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (9, 'Boolean Blind True', 'SQL_INJECTION', ''' AND 1=1--', 'Boolean blind - true condition', 'MEDIUM', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (10, 'Boolean Blind False', 'SQL_INJECTION', ''' AND 1=2--', 'Boolean blind - false condition', 'MEDIUM', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (11, 'Basic Script', 'XSS', '<script>alert(1)</script>', 'Basic XSS script tag', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (12, 'IMG Onerror', 'XSS', '<img src=x onerror=alert(1)>', 'XSS via img onerror', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (13, 'SVG Onload', 'XSS', '<svg onload=alert(1)>', 'XSS via SVG onload', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (14, 'Body Onload', 'XSS', '<body onload=alert(1)>', 'XSS via body onload', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (15, 'Event Handler', 'XSS', '" onmouseover="alert(1)"', 'XSS via event handler injection', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (16, 'JavaScript URI', 'XSS', 'javascript:alert(1)', 'JavaScript protocol handler', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (17, 'Data URI', 'XSS', 'data:text/html,<script>alert(1)</script>', 'XSS via data URI', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (18, 'Encoded Script', 'XSS', '%3Cscript%3Ealert(1)%3C/script%3E', 'URL encoded XSS', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (19, 'Double Encoded', 'XSS', '%253Cscript%253Ealert(1)%253C/script%253E', 'Double URL encoded XSS', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (20, 'Template Injection', 'XSS', '{{constructor.constructor(''alert(1)'')()}}', 'Template injection XSS', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (21, 'Basic Traversal', 'PATH_TRAVERSAL', '../../../etc/passwd', 'Basic path traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (22, 'Windows Traversal', 'PATH_TRAVERSAL', '..\\..\\..\\windows\\system32\\config\\sam', 'Windows path traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (23, 'Encoded Traversal', 'PATH_TRAVERSAL', '..%2F..%2F..%2Fetc%2Fpasswd', 'URL encoded traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (24, 'Double Encoded', 'PATH_TRAVERSAL', '..%252F..%252F..%252Fetc%252Fpasswd', 'Double encoded traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (25, 'Null Byte', 'PATH_TRAVERSAL', '../../../etc/passwd%00.jpg', 'Null byte injection', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (26, 'UTF-8 Encoded', 'PATH_TRAVERSAL', '..%c0%af..%c0%af..%c0%afetc/passwd', 'UTF-8 encoded traversal', 'MEDIUM', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (27, 'Absolute Path', 'PATH_TRAVERSAL', '/etc/passwd', 'Absolute path injection', 'MEDIUM', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (28, 'Dot Dot Slash Variations', 'PATH_TRAVERSAL', '....//....//....//etc/passwd', 'Filter bypass variation', 'MEDIUM', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (29, 'Semicolon Chain', 'COMMAND_INJECTION', '; ls -la', 'Command chaining with semicolon', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (30, 'Pipe Chain', 'COMMAND_INJECTION', '| cat /etc/passwd', 'Command piping', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (31, 'Backtick Exec', 'COMMAND_INJECTION', '`id`', 'Backtick command execution', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (32, 'Dollar Paren', 'COMMAND_INJECTION', '$(id)', 'Dollar-paren command execution', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (33, 'AND Chain', 'COMMAND_INJECTION', '&& cat /etc/passwd', 'AND command chaining', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (34, 'OR Chain', 'COMMAND_INJECTION', '|| cat /etc/passwd', 'OR command chaining', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (35, 'Newline Injection', 'COMMAND_INJECTION', '\nid', 'Newline command injection', 'HIGH', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (36, 'Windows Command', 'COMMAND_INJECTION', '& dir', 'Windows command injection', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (37, 'CRLF Injection', 'HEADER_INJECTION', '\r\nX-Injected: true', 'CRLF header injection', 'HIGH', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (38, 'Host Override', 'HEADER_INJECTION', 'evil.com', 'Host header injection', 'MEDIUM', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (39, 'X-Forwarded-For', 'HEADER_INJECTION', '127.0.0.1', 'IP spoofing via X-Forwarded-For', 'MEDIUM', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (40, 'X-Forwarded-Host', 'HEADER_INJECTION', 'evil.com', 'Host spoofing via X-Forwarded-Host', 'MEDIUM', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (41, 'Empty Token', 'AUTH_BYPASS', '', 'Empty authentication token', 'HIGH', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (42, 'Null Token', 'AUTH_BYPASS', 'null', 'Null string token', 'HIGH', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (43, 'Admin Role', 'AUTH_BYPASS', '{"role":"admin"}', 'Role escalation attempt', 'CRITICAL', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (44, 'JWT None Alg', 'AUTH_BYPASS', 'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.', 'JWT with none algorithm', 'CRITICAL', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload (id, name, category, payload, description, severity, enabled, created_at, updated_at, version) VALUES (45, 'Basic Auth Bypass', 'AUTH_BYPASS', 'Basic YWRtaW46YWRtaW4=', 'Basic auth with admin:admin', 'HIGH', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);


--
-- Data for Name: license; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.license (id, license_type, activated_at, expires_at, status, evaluation_days, app_version, created_at, updated_at, notes, version) VALUES (1, 'EVALUATION', '2026-01-02 06:41:13.307794', '2027-01-02 06:41:13.307794', 'ACTIVE', 365, '1.0.0', '2026-01-02 06:41:13.307794', '2026-01-02 06:41:13.307794', NULL, 0);


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) VALUES (1, '13', '<< Flyway Baseline >>', 'BASELINE', '<< Flyway Baseline >>', NULL, 'null', '2026-03-10 02:30:55.742705', 0, true);


--
-- Data for Name: custom_script; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.custom_script (id, script_content, name, tool_name, category, test_type, description, tool_type, tools_used, parameters, risk_level, status, uploaded_by, uploaded_by_username, approved_by, approved_by_username, approved_at, rejection_reason, validation_result, checksum, version, original_filename, created_at, updated_at, script_version, purpose) VALUES (4, '"""
Custom Nmap Vulnerability Scanner Script
Performs vulnerability scanning using nmap with NSE scripts.
"""
import subprocess
import json
import re
from typing import Dict, Any, List
SCRIPT_INFO = {
    "name": "Nmap Vulnerability Scanner",
    "tool_name": "NMAP_VULN_CUSTOM",
    "category": "NETWORK",
    "test_type": "vulnerability",
    "description": "Performs network vulnerability scanning using nmap with NSE vulnerability scripts",
    "tools_used": ["nmap"],
    "parameters": [
        {
            "name": "scan_type",
            "type": "select",
            "options": ["quick", "standard", "deep"],
            "default": "standard",
            "description": "Scan intensity level"
        },
        {
            "name": "ports",
            "type": "string",
            "default": "1-1000",
            "description": "Port range to scan (e.g., 1-1000, 22,80,443)"
        },
        {
            "name": "scripts",
            "type": "string",
            "default": "vuln",
            "description": "NSE script categories to run (e.g., vuln, default, safe)"
        }
    ],
    "risk_level": "LOW"
}
def execute(target: str, parameters: Dict[str, Any], timeout: int) -> Dict[str, Any]:
    """
    Execute nmap vulnerability scan against target.
    Args:
        target: IP address or hostname to scan
        parameters: Scan configuration parameters
        timeout: Execution timeout in seconds
    Returns:
        Dictionary with scan results
    """
    findings = []
    console_output = []
    # Get parameters with defaults
    scan_type = parameters.get("scan_type", "standard")
    ports = parameters.get("ports", "1-1000")
    scripts = parameters.get("scripts", "vuln")
    # Build nmap command based on scan type
    cmd = ["nmap", "-oX", "-"]  # XML output to stdout
    if scan_type == "quick":
        cmd.extend(["-T4", "-F"])  # Fast scan, top 100 ports
    elif scan_type == "deep":
        cmd.extend(["-T3", "-sV", "-sC", "-A"])  # Thorough scan
    else:  # standard
        cmd.extend(["-T4", "-sV"])  # Service detection
    # Add port specification
    cmd.extend(["-p", ports])
    # Add NSE scripts
    cmd.extend(["--script", scripts])
    # Add target
    cmd.append(target)
    command_str = " ".join(cmd)
    console_output.append(f"Executing: {command_str}")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        exit_code = result.returncode
        raw_output = result.stdout
        if result.stderr:
            console_output.append(f"stderr: {result.stderr}")
        # Parse nmap XML output for findings
        findings = parse_nmap_output(raw_output, target)
        # Generate summary
        high_count = len([f for f in findings if f.get("severity") == "HIGH"])
        medium_count = len([f for f in findings if f.get("severity") == "MEDIUM"])
        low_count = len([f for f in findings if f.get("severity") == "LOW"])
        info_count = len([f for f in findings if f.get("severity") == "INFO"])
        summary = f"Nmap scan completed. Found {len(findings)} findings: {high_count} HIGH, {medium_count} MEDIUM, {low_count} LOW, {info_count} INFO"
        console_output.append(summary)
        return {
            "findings": findings,
            "summary": summary,
            "raw_output": raw_output,
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": exit_code,
            "error_message": None
        }
    except subprocess.TimeoutExpired:
        return {
            "findings": [],
            "summary": "Scan timed out",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": f"Scan timed out after {timeout} seconds"
        }
    except Exception as e:
        return {
            "findings": [],
            "summary": f"Scan failed: {str(e)}",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": str(e)
        }
def parse_nmap_output(xml_output: str, target: str) -> List[Dict[str, Any]]:
    """Parse nmap XML output and extract findings."""
    findings = []
    # Simple regex-based parsing for common patterns
    # In production, use xml.etree.ElementTree for proper parsing
    # Find open ports
    port_pattern = r''<port protocol="(\w+)" portid="(\d+)".*?<state state="open".*?<service name="([^"]*)"''
    for match in re.finditer(port_pattern, xml_output, re.DOTALL):
        protocol, port, service = match.groups()
        findings.append({
            "title": f"Open Port: {port}/{protocol}",
            "severity": "INFO",
            "description": f"Port {port}/{protocol} is open running {service}",
            "target": target,
            "port": int(port),
            "service": service
        })
    # Find script output (vulnerabilities)
    script_pattern = r''<script id="([^"]+)".*?output="([^"]*)"''
    for match in re.finditer(script_pattern, xml_output, re.DOTALL):
        script_id, output = match.groups()
        # Determine severity based on script type
        severity = "INFO"
        if "vuln" in script_id.lower():
            if "VULNERABLE" in output.upper():
                severity = "HIGH"
            else:
                severity = "MEDIUM"
        if output.strip():
            findings.append({
                "title": f"NSE Script: {script_id}",
                "severity": severity,
                "description": output[:500],  # Truncate long output
                "target": target,
                "script": script_id
            })
    return findings
', 'Nmap Vulnerability Scanner', 'NMAP_VULN_CUSTOM', 'NETWORK', 'vulnerability', 'Performs network vulnerability scanning using nmap with NSE vulnerability scripts', 'SCRIPT', '["nmap"]', '[{"name":"scan_type","type":"select","options":["quick","standard","deep"],"default":"standard","description":"Scan intensity level"},{"name":"ports","type":"string","default":"1-1000","description":"Port range to scan (e.g., 1-1000, 22,80,443)"},{"name":"scripts","type":"string","default":"vuln","description":"NSE script categories to run (e.g., vuln, default, safe)"}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 06:23:59.927', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"NMAP_VULN_CUSTOM","risk_level":"LOW","tools_used":["nmap"],"name":"Nmap Vulnerability Scanner","description":"Performs network vulnerability scanning using nmap with NSE vulnerability scripts","category":"NETWORK","parameters":[{"name":"scan_type","type":"select","options":["quick","standard","deep"],"default":"standard","description":"Scan intensity level"},{"name":"ports","type":"string","default":"1-1000","description":"Port range to scan (e.g., 1-1000, 22,80,443)"},{"name":"scripts","type":"string","default":"vuln","description":"NSE script categories to run (e.g., vuln, default, safe)"}],"test_type":"vulnerability"}}', 'edda2ac28c1e322dd8586ee553dfab3ed951c10f63aac2224048d84dd6f54c2a', 1, 'nmap_vuln_scan.py', '2026-01-07 06:23:48.017', '2026-01-07 06:23:59.92479', NULL, 'SECURITY');
INSERT INTO public.custom_script (id, script_content, name, tool_name, category, test_type, description, tool_type, tools_used, parameters, risk_level, status, uploaded_by, uploaded_by_username, approved_by, approved_by_username, approved_at, rejection_reason, validation_result, checksum, version, original_filename, created_at, updated_at, script_version, purpose) VALUES (6, '"""
Custom SQLMap SQL Injection Scanner Script
Performs SQL injection vulnerability scanning using sqlmap.
"""
import subprocess
import json
import re
from typing import Dict, Any, List
SCRIPT_INFO = {
    "name": "SQLMap Injection Scanner",
    "tool_name": "SQLMAP_INJECT_CUSTOM",
    "category": "APPLICATION",
    "test_type": "vulnerability",
    "description": "Performs automated SQL injection detection and exploitation testing using sqlmap",
    "tools_used": ["sqlmap"],
    "parameters": [
        {
            "name": "method",
            "type": "select",
            "options": ["GET", "POST"],
            "default": "GET",
            "description": "HTTP method to use"
        },
        {
            "name": "data",
            "type": "string",
            "default": "",
            "description": "POST data (e.g., id=1&name=test)"
        },
        {
            "name": "level",
            "type": "select",
            "options": ["1", "2", "3", "4", "5"],
            "default": "1",
            "description": "Level of tests to perform (1-5)"
        },
        {
            "name": "risk",
            "type": "select",
            "options": ["1", "2", "3"],
            "default": "1",
            "description": "Risk of tests to perform (1-3)"
        },
        {
            "name": "dbms",
            "type": "select",
            "options": ["auto", "mysql", "postgresql", "mssql", "oracle", "sqlite"],
            "default": "auto",
            "description": "Target database management system"
        }
    ],
    "risk_level": "MEDIUM"
}
def execute(target: str, parameters: Dict[str, Any], timeout: int) -> Dict[str, Any]:
    """
    Execute sqlmap SQL injection scan against target URL.
    Args:
        target: URL with parameter to test (e.g., http://example.com/page?id=1)
        parameters: Scan configuration parameters
        timeout: Execution timeout in seconds
    Returns:
        Dictionary with scan results
    """
    findings = []
    console_output = []
    # Get parameters with defaults
    method = parameters.get("method", "GET")
    post_data = parameters.get("data", "")
    level = parameters.get("level", "1")
    risk = parameters.get("risk", "1")
    dbms = parameters.get("dbms", "auto")
    # Build sqlmap command
    cmd = [
        "sqlmap",
        "-u", target,
        "--batch",  # Non-interactive mode
        "--level", level,
        "--risk", risk,
        "--output-dir=/tmp/sqlmap_output",
        "--forms" if not post_data else ""
    ]
    # Remove empty strings from command
    cmd = [c for c in cmd if c]
    if method == "POST" and post_data:
        cmd.extend(["--data", post_data])
    if dbms != "auto":
        cmd.extend(["--dbms", dbms])
    # Add timeout
    cmd.extend(["--timeout", str(min(30, timeout // 10))])
    command_str = " ".join(cmd)
    console_output.append(f"Executing: {command_str}")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        exit_code = result.returncode
        raw_output = result.stdout + "\n" + result.stderr
        console_output.append(f"Exit code: {exit_code}")
        # Parse sqlmap output
        findings = parse_sqlmap_output(raw_output, target)
        # Generate summary
        vuln_count = len([f for f in findings if f.get("severity") in ["HIGH", "CRITICAL"]])
        info_count = len([f for f in findings if f.get("severity") == "INFO"])
        if vuln_count > 0:
            summary = f"SQLMap scan found {vuln_count} SQL injection vulnerabilities!"
        else:
            summary = f"SQLMap scan completed. No SQL injection vulnerabilities detected. {info_count} info items found."
        console_output.append(summary)
        return {
            "findings": findings,
            "summary": summary,
            "raw_output": raw_output,
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": exit_code,
            "error_message": None
        }
    except subprocess.TimeoutExpired:
        return {
            "findings": [],
            "summary": "Scan timed out",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": f"Scan timed out after {timeout} seconds"
        }
    except Exception as e:
        return {
            "findings": [],
            "summary": f"Scan failed: {str(e)}",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": str(e)
        }
def parse_sqlmap_output(output: str, target: str) -> List[Dict[str, Any]]:
    """Parse sqlmap output and extract findings."""
    findings = []
    output_lower = output.lower()
    # Check for SQL injection detection
    injection_types = [
        ("boolean-based blind", "HIGH"),
        ("time-based blind", "HIGH"),
        ("error-based", "HIGH"),
        ("union-based", "HIGH"),
        ("stacked queries", "HIGH"),
        ("inline queries", "HIGH")
    ]
    for injection_type, severity in injection_types:
        if injection_type in output_lower:
            # Extract parameter name if possible
            param_match = re.search(r"parameter[:\s]+[''\"]?(\w+)[''\"]?", output, re.IGNORECASE)
            param_name = param_match.group(1) if param_match else "unknown"
            findings.append({
                "title": f"SQL Injection Detected ({injection_type})",
                "severity": severity,
                "description": f"SQL injection vulnerability found using {injection_type} technique on parameter ''{param_name}''",
                "target": target,
                "parameter": param_name,
                "technique": injection_type
            })
    # Check for database information
    db_patterns = [
        (r"back-end DBMS:\s*([^\n]+)", "Database Identified"),
        (r"web server operating system:\s*([^\n]+)", "Server OS Identified"),
        (r"web application technology:\s*([^\n]+)", "Technology Stack Identified")
    ]
    for pattern, title in db_patterns:
        match = re.search(pattern, output, re.IGNORECASE)
        if match:
            findings.append({
                "title": title,
                "severity": "INFO",
                "description": match.group(1).strip(),
                "target": target
            })
    # Check if no vulnerabilities found
    if not findings and ("not injectable" in output_lower or "no parameter" in output_lower):
        findings.append({
            "title": "No SQL Injection Found",
            "severity": "INFO",
            "description": "SQLMap did not detect any SQL injection vulnerabilities in the tested parameters",
            "target": target
        })
    return findings
', 'SQLMap Injection Scanner', 'SQLMAP_INJECT_CUSTOM', 'APPLICATION', 'vulnerability', 'Performs automated SQL injection detection and exploitation testing using sqlmap', 'SCRIPT', '["sqlmap"]', '[{"name":"method","type":"select","options":["GET","POST"],"default":"GET","description":"HTTP method to use"},{"name":"data","type":"string","default":"","description":"POST data (e.g., id=1&name=test)"},{"name":"level","type":"select","options":["1","2","3","4","5"],"default":"1","description":"Level of tests to perform (1-5)"},{"name":"risk","type":"select","options":["1","2","3"],"default":"1","description":"Risk of tests to perform (1-3)"},{"name":"dbms","type":"select","options":["auto","mysql","postgresql","mssql","oracle","sqlite"],"default":"auto","description":"Target database management system"}]', 'MEDIUM', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 06:25:28.469', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"SQLMAP_INJECT_CUSTOM","risk_level":"MEDIUM","tools_used":["sqlmap"],"name":"SQLMap Injection Scanner","description":"Performs automated SQL injection detection and exploitation testing using sqlmap","category":"APPLICATION","parameters":[{"name":"method","type":"select","options":["GET","POST"],"default":"GET","description":"HTTP method to use"},{"name":"data","type":"string","default":"","description":"POST data (e.g., id=1&name=test)"},{"name":"level","type":"select","options":["1","2","3","4","5"],"default":"1","description":"Level of tests to perform (1-5)"},{"name":"risk","type":"select","options":["1","2","3"],"default":"1","description":"Risk of tests to perform (1-3)"},{"name":"dbms","type":"select","options":["auto","mysql","postgresql","mssql","oracle","sqlite"],"default":"auto","description":"Target database management system"}],"test_type":"vulnerability"}}', 'b940362b847688e0413b0b24ece33349e2ae8457bd9aa650742bae2ac1ead86c', 1, 'sqlmap_injection_scan.py', '2026-01-07 06:25:28.38', '2026-01-07 06:25:28.46791', NULL, 'SECURITY');
INSERT INTO public.custom_script (id, script_content, name, tool_name, category, test_type, description, tool_type, tools_used, parameters, risk_level, status, uploaded_by, uploaded_by_username, approved_by, approved_by_username, approved_at, rejection_reason, validation_result, checksum, version, original_filename, created_at, updated_at, script_version, purpose) VALUES (5, '"""
Custom Nikto Web Vulnerability Scanner Script
Performs web server vulnerability scanning using nikto.
"""
import subprocess
import json
import re
from typing import Dict, Any, List
SCRIPT_INFO = {
    "name": "Nikto Web Vulnerability Scanner",
    "tool_name": "NIKTO_WEB_CUSTOM",
    "category": "WEB",
    "test_type": "vulnerability",
    "description": "Performs comprehensive web server vulnerability scanning using nikto",
    "tools_used": ["nikto"],
    "parameters": [
        {
            "name": "ssl",
            "type": "boolean",
            "default": False,
            "description": "Use SSL/HTTPS for connection"
        },
        {
            "name": "port",
            "type": "number",
            "default": 80,
            "description": "Target port (default 80, or 443 for SSL)"
        },
        {
            "name": "tuning",
            "type": "select",
            "options": ["1", "2", "3", "4", "5", "6", "7", "8", "9", "x"],
            "default": "x",
            "description": "Scan tuning (1=files, 2=misconfig, 3=info, x=all)"
        },
        {
            "name": "maxtime",
            "type": "number",
            "default": 3600,
            "description": "Maximum scan time in seconds"
        }
    ],
    "risk_level": "LOW"
}
def execute(target: str, parameters: Dict[str, Any], timeout: int) -> Dict[str, Any]:
    """
    Execute nikto web scan against target.
    Args:
        target: URL or hostname to scan
        parameters: Scan configuration parameters
        timeout: Execution timeout in seconds
    Returns:
        Dictionary with scan results
    """
    findings = []
    console_output = []
    # Get parameters with defaults
    use_ssl = parameters.get("ssl", False)
    port = parameters.get("port", 443 if use_ssl else 80)
    tuning = parameters.get("tuning", "x")
    maxtime = parameters.get("maxtime", 3600)
    # Clean target (remove protocol if present)
    clean_target = target
    if target.startswith("http://"):
        clean_target = target[7:]
    elif target.startswith("https://"):
        clean_target = target[8:]
        use_ssl = True
    # Build nikto command
    cmd = ["nikto", "-h", clean_target, "-p", str(port), "-Format", "json"]
    if use_ssl:
        cmd.append("-ssl")
    cmd.extend(["-Tuning", tuning])
    cmd.extend(["-maxtime", str(min(maxtime, timeout - 60))])
    # Disable interactive prompts
    cmd.append("-nointeractive")
    command_str = " ".join(cmd)
    console_output.append(f"Executing: {command_str}")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        exit_code = result.returncode
        raw_output = result.stdout
        if result.stderr:
            console_output.append(f"stderr: {result.stderr}")
        # Parse nikto output
        findings = parse_nikto_output(raw_output, clean_target, port)
        # Generate summary
        high_count = len([f for f in findings if f.get("severity") == "HIGH"])
        medium_count = len([f for f in findings if f.get("severity") == "MEDIUM"])
        low_count = len([f for f in findings if f.get("severity") == "LOW"])
        info_count = len([f for f in findings if f.get("severity") == "INFO"])
        summary = f"Nikto scan completed. Found {len(findings)} findings: {high_count} HIGH, {medium_count} MEDIUM, {low_count} LOW, {info_count} INFO"
        console_output.append(summary)
        return {
            "findings": findings,
            "summary": summary,
            "raw_output": raw_output,
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": exit_code,
            "error_message": None
        }
    except subprocess.TimeoutExpired:
        return {
            "findings": [],
            "summary": "Scan timed out",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": f"Scan timed out after {timeout} seconds"
        }
    except Exception as e:
        return {
            "findings": [],
            "summary": f"Scan failed: {str(e)}",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": str(e)
        }
def parse_nikto_output(output: str, target: str, port: int) -> List[Dict[str, Any]]:
    """Parse nikto output and extract findings."""
    findings = []
    # Try to parse as JSON first
    try:
        data = json.loads(output)
        if isinstance(data, dict) and "vulnerabilities" in data:
            for vuln in data["vulnerabilities"]:
                findings.append({
                    "title": vuln.get("msg", "Unknown vulnerability"),
                    "severity": categorize_nikto_severity(vuln.get("OSVDB", "")),
                    "description": vuln.get("msg", ""),
                    "target": f"{target}:{port}",
                    "osvdb": vuln.get("OSVDB"),
                    "uri": vuln.get("uri", "/")
                })
            return findings
    except json.JSONDecodeError:
        pass
    # Fallback: Parse text output line by line
    lines = output.split("\n")
    for line in lines:
        line = line.strip()
        # Skip empty lines and header lines
        if not line or line.startswith("-") or line.startswith("Nikto"):
            continue
        # Look for vulnerability patterns
        if "+ " in line:
            finding_text = line.split("+ ", 1)[-1]
            severity = "INFO"
            if any(word in finding_text.lower() for word in ["vulnerable", "cve-", "exploit"]):
                severity = "HIGH"
            elif any(word in finding_text.lower() for word in ["outdated", "version", "disclosure"]):
                severity = "MEDIUM"
            elif any(word in finding_text.lower() for word in ["header", "missing", "cookie"]):
                severity = "LOW"
            findings.append({
                "title": finding_text[:100],
                "severity": severity,
                "description": finding_text,
                "target": f"{target}:{port}"
            })
    return findings
def categorize_nikto_severity(osvdb: str) -> str:
    """Categorize severity based on OSVDB reference."""
    if not osvdb or osvdb == "0":
        return "INFO"
    # OSVDB entries typically indicate known issues
    return "MEDIUM"
', 'Nikto Web Vulnerability Scanner', 'NIKTO_WEB_CUSTOM', 'WEB', 'vulnerability', 'Performs comprehensive web server vulnerability scanning using nikto', 'SCRIPT', '["nikto"]', '[{"name":"ssl","type":"boolean","default":false,"description":"Use SSL/HTTPS for connection"},{"name":"port","type":"number","default":80,"description":"Target port (default 80, or 443 for SSL)"},{"name":"tuning","type":"select","options":["1","2","3","4","5","6","7","8","9","x"],"default":"x","description":"Scan tuning (1=files, 2=misconfig, 3=info, x=all)"},{"name":"maxtime","type":"number","default":3600,"description":"Maximum scan time in seconds"}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-08 07:37:28.634', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"NIKTO_WEB_CUSTOM","risk_level":"LOW","tools_used":["nikto"],"name":"Nikto Web Vulnerability Scanner","description":"Performs comprehensive web server vulnerability scanning using nikto","category":"WEB","parameters":[{"name":"ssl","type":"boolean","default":false,"description":"Use SSL/HTTPS for connection"},{"name":"port","type":"number","default":80,"description":"Target port (default 80, or 443 for SSL)"},{"name":"tuning","type":"select","options":["1","2","3","4","5","6","7","8","9","x"],"default":"x","description":"Scan tuning (1=files, 2=misconfig, 3=info, x=all)"},{"name":"maxtime","type":"number","default":3600,"description":"Maximum scan time in seconds"}],"test_type":"vulnerability"}}', 'a2e6cbd0a66f698e72bb4e64364d38b1bdadc6ba37a16cdfc5fff976207e1903', 2, 'nikto_web_scan.py', '2026-01-07 06:24:53.512', '2026-01-08 07:37:28.63321', NULL, 'SECURITY');
INSERT INTO public.custom_script (id, script_content, name, tool_name, category, test_type, description, tool_type, tools_used, parameters, risk_level, status, uploaded_by, uploaded_by_username, approved_by, approved_by_username, approved_at, rejection_reason, validation_result, checksum, version, original_filename, created_at, updated_at, script_version, purpose) VALUES (7, '"""
Custom Nuclei Template Scanner Script
Performs vulnerability scanning using nuclei templates.
"""
import subprocess
import json
from typing import Dict, Any, List
SCRIPT_INFO = {
    "name": "Nuclei Template Scanner",
    "tool_name": "NUCLEI_TEMPLATE_CUSTOM",
    "category": "APPLICATION",
    "test_type": "vulnerability",
    "description": "Performs fast and customizable vulnerability scanning using nuclei templates",
    "tools_used": ["nuclei"],
    "parameters": [
        {
            "name": "severity",
            "type": "select",
            "options": ["info", "low", "medium", "high", "critical", "all"],
            "default": "all",
            "description": "Minimum severity level to report"
        },
        {
            "name": "tags",
            "type": "string",
            "default": "",
            "description": "Template tags to include (e.g., cve,rce,lfi)"
        },
        {
            "name": "exclude_tags",
            "type": "string",
            "default": "dos",
            "description": "Template tags to exclude"
        },
        {
            "name": "rate_limit",
            "type": "number",
            "default": 150,
            "description": "Maximum requests per second"
        },
        {
            "name": "concurrency",
            "type": "number",
            "default": 25,
            "description": "Number of concurrent templates"
        }
    ],
    "risk_level": "LOW"
}
def execute(target: str, parameters: Dict[str, Any], timeout: int) -> Dict[str, Any]:
    """
    Execute nuclei scan against target.
    Args:
        target: URL or IP to scan
        parameters: Scan configuration parameters
        timeout: Execution timeout in seconds
    Returns:
        Dictionary with scan results
    """
    findings = []
    console_output = []
    # Get parameters with defaults
    severity = parameters.get("severity", "all")
    tags = parameters.get("tags", "")
    exclude_tags = parameters.get("exclude_tags", "dos")
    rate_limit = parameters.get("rate_limit", 150)
    concurrency = parameters.get("concurrency", 25)
    # Build nuclei command
    cmd = [
        "nuclei",
        "-u", target,
        "-json",  # JSON output
        "-silent",  # Suppress banner
        "-rate-limit", str(rate_limit),
        "-c", str(concurrency)
    ]
    # Add severity filter
    if severity != "all":
        cmd.extend(["-severity", severity])
    # Add tags
    if tags:
        cmd.extend(["-tags", tags])
    # Add exclude tags
    if exclude_tags:
        cmd.extend(["-exclude-tags", exclude_tags])
    command_str = " ".join(cmd)
    console_output.append(f"Executing: {command_str}")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        exit_code = result.returncode
        raw_output = result.stdout
        if result.stderr:
            # Filter out noise from stderr
            stderr_lines = [l for l in result.stderr.split("\n")
                          if l and not l.startswith("[INF]") and not l.startswith("[WRN]")]
            if stderr_lines:
                console_output.append(f"stderr: {''; ''.join(stderr_lines[:5])}")
        # Parse nuclei JSON output (one JSON object per line)
        findings = parse_nuclei_output(raw_output, target)
        # Generate summary
        critical_count = len([f for f in findings if f.get("severity") == "CRITICAL"])
        high_count = len([f for f in findings if f.get("severity") == "HIGH"])
        medium_count = len([f for f in findings if f.get("severity") == "MEDIUM"])
        low_count = len([f for f in findings if f.get("severity") == "LOW"])
        info_count = len([f for f in findings if f.get("severity") == "INFO"])
        summary = (f"Nuclei scan completed. Found {len(findings)} findings: "
                  f"{critical_count} CRITICAL, {high_count} HIGH, {medium_count} MEDIUM, "
                  f"{low_count} LOW, {info_count} INFO")
        console_output.append(summary)
        return {
            "findings": findings,
            "summary": summary,
            "raw_output": raw_output,
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": exit_code,
            "error_message": None
        }
    except subprocess.TimeoutExpired:
        return {
            "findings": [],
            "summary": "Scan timed out",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": f"Scan timed out after {timeout} seconds"
        }
    except Exception as e:
        return {
            "findings": [],
            "summary": f"Scan failed: {str(e)}",
            "raw_output": "",
            "console_output": "\n".join(console_output),
            "command_executed": command_str,
            "exit_code": -1,
            "error_message": str(e)
        }
def parse_nuclei_output(output: str, target: str) -> List[Dict[str, Any]]:
    """Parse nuclei JSON output and extract findings."""
    findings = []
    for line in output.strip().split("\n"):
        if not line:
            continue
        try:
            data = json.loads(line)
            # Map nuclei severity to standard format
            severity_map = {
                "info": "INFO",
                "low": "LOW",
                "medium": "MEDIUM",
                "high": "HIGH",
                "critical": "CRITICAL"
            }
            nuclei_severity = data.get("info", {}).get("severity", "info")
            severity = severity_map.get(nuclei_severity.lower(), "INFO")
            finding = {
                "title": data.get("info", {}).get("name", "Unknown"),
                "severity": severity,
                "description": data.get("info", {}).get("description", ""),
                "target": data.get("matched-at", target),
                "template_id": data.get("template-id"),
                "template_path": data.get("template"),
                "matcher_name": data.get("matcher-name"),
                "type": data.get("type"),
                "extracted_results": data.get("extracted-results", [])
            }
            # Add CVE if present
            cve_ids = data.get("info", {}).get("classification", {}).get("cve-id", [])
            if cve_ids:
                finding["cve"] = cve_ids
            # Add reference URLs
            refs = data.get("info", {}).get("reference", [])
            if refs:
                finding["references"] = refs
            findings.append(finding)
        except json.JSONDecodeError:
            # Skip non-JSON lines (could be progress indicators)
            continue
    return findings
', 'Nuclei Template Scanner', 'NUCLEI_TEMPLATE_CUSTOM', 'APPLICATION', 'vulnerability', 'Performs fast and customizable vulnerability scanning using nuclei templates', 'SCRIPT', '["nuclei"]', '[{"name":"severity","type":"select","options":["info","low","medium","high","critical","all"],"default":"all","description":"Minimum severity level to report"},{"name":"tags","type":"string","default":"","description":"Template tags to include (e.g., cve,rce,lfi)"},{"name":"exclude_tags","type":"string","default":"dos","description":"Template tags to exclude"},{"name":"rate_limit","type":"number","default":150,"description":"Maximum requests per second"},{"name":"concurrency","type":"number","default":25,"description":"Number of concurrent templates"}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 06:25:28.748', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"NUCLEI_TEMPLATE_CUSTOM","risk_level":"LOW","tools_used":["nuclei"],"name":"Nuclei Template Scanner","description":"Performs fast and customizable vulnerability scanning using nuclei templates","category":"APPLICATION","parameters":[{"name":"severity","type":"select","options":["info","low","medium","high","critical","all"],"default":"all","description":"Minimum severity level to report"},{"name":"tags","type":"string","default":"","description":"Template tags to include (e.g., cve,rce,lfi)"},{"name":"exclude_tags","type":"string","default":"dos","description":"Template tags to exclude"},{"name":"rate_limit","type":"number","default":150,"description":"Maximum requests per second"},{"name":"concurrency","type":"number","default":25,"description":"Number of concurrent templates"}],"test_type":"vulnerability"}}', '8ddf198e19e567cc39f228feafbbad370f81392cc2e3b4188cb26fcbe62cfda1', 1, 'nuclei_template_scan.py', '2026-01-07 06:25:28.657', '2026-01-07 06:25:28.746507', NULL, 'SECURITY');
INSERT INTO public.custom_script (id, script_content, name, tool_name, category, test_type, description, tool_type, tools_used, parameters, risk_level, status, uploaded_by, uploaded_by_username, approved_by, approved_by_username, approved_at, rejection_reason, validation_result, checksum, version, original_filename, created_at, updated_at, script_version, purpose) VALUES (8, '#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Trivy Kubernetes Multi-Context Scanner - Custom Script Version
Scans Kubernetes clusters using Trivy for vulnerabilities, misconfigurations,
and secrets. Supports multiple contexts and namespace filtering.
Requirements:
  - kubectl installed and configured
  - trivy installed and in PATH
  - Access to each kube context you wish to scan
"""
import json
import logging
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple, Any
logger = logging.getLogger(__name__)
# =============================================================================
# SCRIPT_INFO - Required metadata for custom script registration
# =============================================================================
SCRIPT_INFO = {
    "name": "Trivy Kubernetes Scanner",
    "tool_name": "trivy_k8s_multicontext",  # Unique identifier
    "category": "KUBERNETES",
    "test_type": "vulnerability",
    "description": "Scans Kubernetes clusters across multiple contexts using Trivy. Detects vulnerabilities, misconfigurations, and exposed secrets in workloads.",
    "tool_type": "script",
    "tools_used": ["trivy", "kubectl"],
    "parameters": [
        {
            "name": "include_namespaces",
            "label": "Include Namespaces",
            "type": "text",
            "hint": "Comma-separated namespaces to include (empty = all)",
            "default": "",
            "required": False
        },
        {
            "name": "exclude_namespaces",
            "label": "Exclude Namespaces",
            "type": "text",
            "hint": "Namespaces to exclude from scan (comma-separated)",
            "default": "kube-public,kube-system,kube-node-lease",
            "required": False
        },
        {
            "name": "report_type",
            "label": "Report Type",
            "type": "select",
            "options": ["summary", "all"],
            "default": "summary",
            "required": False
        },
        {
            "name": "parallel",
            "label": "Parallel Scans",
            "type": "number",
            "hint": "Number of concurrent namespace scans",
            "default": 2,
            "required": False
        },
        {
            "name": "cluster_scan",
            "label": "Cluster-wide Scan",
            "type": "boolean",
            "hint": "Also run a cluster-wide scan",
            "default": False,
            "required": False
        }
    ],
    "risk_level": "LOW"
}
# =============================================================================
# Helper Functions
# =============================================================================
def check_binary(cmd: str) -> str:
    """Check if binary exists in PATH, raise if not found"""
    path = shutil.which(cmd)
    if not path:
        raise EnvironmentError(f"Required binary not found: {cmd}")
    return path
def run_command(cmd: List[str], timeout: Optional[int] = None) -> Tuple[int, str, str]:
    """Run a command and return (exit_code, stdout, stderr)"""
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return 124, "", f"Command timed out after {timeout}s"
    except Exception as e:
        return 1, "", str(e)
def create_result(
    findings: List[Dict],
    summary: Dict,
    raw_output: str = "",
    console_output: str = "",
    command_executed: str = "",
    exit_code: int = 0,
    error_message: str = None
) -> Dict:
    """Create a standardized result dict"""
    return {
        "findings": findings,
        "summary": summary,
        "raw_output": raw_output,
        "console_output": console_output,
        "command_executed": command_executed,
        "exit_code": exit_code,
        "error_message": error_message,
        "executed_at": datetime.now(timezone.utc).isoformat()
    }
def get_contexts(kubectl: str) -> List[str]:
    """Get all available Kubernetes contexts."""
    rc, out, err = run_command([kubectl, "config", "get-contexts", "-o", "name"])
    if rc != 0:
        raise RuntimeError(f"kubectl failed to list contexts: {err.strip()}")
    return [line.strip() for line in out.splitlines() if line.strip()]
def get_namespaces(kubectl: str, context: str) -> List[str]:
    """Get all namespaces for a given context."""
    rc, out, err = run_command([kubectl, "--context", context, "get", "namespaces", "-o", "json"])
    if rc != 0:
        raise RuntimeError(f"kubectl failed to list namespaces for context ''{context}'': {err.strip()}")
    try:
        data = json.loads(out)
    except json.JSONDecodeError:
        raise RuntimeError(f"Failed to parse namespaces JSON for context ''{context}''")
    items = data.get("items", [])
    return [i["metadata"]["name"] for i in items if "metadata" in i and "name" in i["metadata"]]
def trivy_scan_namespace(trivy: str, context: str, namespace: str, report: str = "summary") -> Dict:
    """Run trivy k8s scan for a single namespace."""
    cmd = [trivy, "k8s", context, "--include-namespaces", namespace, "--report", report, "--format", "json"]
    rc, out, err = run_command(cmd, timeout=300)
    result: Dict = {
        "context": context,
        "namespace": namespace,
        "report": report,
        "ok": rc == 0,
        "error": err.strip() if rc != 0 else None,
        "raw": None,
        "command": " ".join(cmd)
    }
    if rc == 0:
        try:
            result["raw"] = json.loads(out)
        except json.JSONDecodeError:
            result["ok"] = False
            result["error"] = "Failed to parse Trivy JSON output"
    return result
def trivy_scan_cluster(trivy: str, context: str, report: str = "summary") -> Dict:
    """Run cluster-wide trivy scan."""
    cmd = [trivy, "k8s", context, "--report", report, "--format", "json"]
    rc, out, err = run_command(cmd, timeout=600)
    result: Dict = {
        "context": context,
        "target": "cluster",
        "report": report,
        "ok": rc == 0,
        "error": err.strip() if rc != 0 else None,
        "raw": None,
        "command": " ".join(cmd)
    }
    if rc == 0:
        try:
            result["raw"] = json.loads(out)
        except json.JSONDecodeError:
            result["ok"] = False
            result["error"] = "Failed to parse Trivy JSON output"
    return result
def extract_findings(scan_results: List[Dict]) -> Tuple[List[Dict], Dict[str, int]]:
    """Extract findings and count vulnerabilities by severity from scan results."""
    findings = []
    counts = {"CRITICAL": 0, "HIGH": 0, "MEDIUM": 0, "LOW": 0, "UNKNOWN": 0}
    for scan in scan_results:
        raw = scan.get("raw")
        if not raw or not isinstance(raw, dict):
            continue
        context = scan.get("context", "unknown")
        namespace = scan.get("namespace", scan.get("target", "unknown"))
        # Trivy k8s output structure
        results = raw.get("Results", [])
        if isinstance(results, list):
            for result in results:
                vulns = result.get("Vulnerabilities", [])
                if isinstance(vulns, list):
                    for vuln in vulns:
                        severity = vuln.get("Severity", "UNKNOWN").upper()
                        if severity in counts:
                            counts[severity] += 1
                        else:
                            counts["UNKNOWN"] += 1
                        findings.append({
                            "type": "vulnerability",
                            "severity": severity,
                            "title": vuln.get("Title", vuln.get("VulnerabilityID", "Unknown")),
                            "vulnerability_id": vuln.get("VulnerabilityID"),
                            "package": vuln.get("PkgName"),
                            "installed_version": vuln.get("InstalledVersion"),
                            "fixed_version": vuln.get("FixedVersion"),
                            "context": context,
                            "namespace": namespace,
                            "target": result.get("Target", "")
                        })
    return findings, counts
# =============================================================================
# Main Execute Function - Required entry point for custom scripts
# =============================================================================
def execute(target: str, parameters: Dict[str, Any], timeout: int) -> Dict[str, Any]:
    """
    Execute Trivy Kubernetes scan.
    Args:
        target: Target specification - Kubernetes context name (e.g., "minikube") or "all"
        parameters: Scan parameters from SCRIPT_INFO
        timeout: Maximum execution time in seconds
    Returns:
        Standardized result dict with findings, summary, raw_output, etc.
    """
    console_log = []
    commands_executed = []
    def log(msg: str):
        timestamp = datetime.now().strftime(''%H:%M:%S'')
        console_log.append(f"[{timestamp}] {msg}")
        logger.info(msg)
    try:
        # Check required tools
        log("Checking required binaries...")
        kubectl = check_binary("kubectl")
        trivy = check_binary("trivy")
        log(f"  kubectl: {kubectl}")
        log(f"  trivy: {trivy}")
        # Extract parameters with defaults
        include_ns = parameters.get("include_namespaces", "")
        exclude_ns = parameters.get("exclude_namespaces", "kube-public")
        report_type = parameters.get("report_type", "summary")
        parallel = int(parameters.get("parallel", 2))
        cluster_scan = parameters.get("cluster_scan", False)
        # Parse namespace filters
        include_list = [ns.strip() for ns in include_ns.split(",") if ns.strip()] if include_ns else []
        exclude_list = [ns.strip() for ns in exclude_ns.split(",") if ns.strip()] if exclude_ns else []
        log(f"Target context: {target}")
        log(f"Report type: {report_type}")
        log(f"Parallel workers: {parallel}")
        # Discover contexts
        all_contexts = get_contexts(kubectl)
        if not all_contexts:
            return create_result(
                findings=[],
                summary={"error": "No Kubernetes contexts found"},
                console_output="\n".join(console_log),
                exit_code=1,
                error_message="No Kubernetes contexts found in kubeconfig"
            )
        # Filter contexts
        if target.lower() == "all":
            contexts = all_contexts
        elif target in all_contexts:
            contexts = [target]
        else:
            available = ", ".join(all_contexts)
            return create_result(
                findings=[],
                summary={"error": f"Context ''{target}'' not found"},
                console_output="\n".join(console_log),
                exit_code=1,
                error_message=f"Context ''{target}'' not found. Available: {available}"
            )
        log(f"Scanning contexts: {contexts}")
        # Collect all scan results
        all_scans = []
        errors = []
        for ctx in contexts:
            log(f"Processing context: {ctx}")
            try:
                namespaces = get_namespaces(kubectl, ctx)
            except Exception as e:
                log(f"  Failed to get namespaces: {e}")
                errors.append(f"Context ''{ctx}'': {str(e)}")
                continue
            # Filter namespaces
            if include_list:
                namespaces = [n for n in namespaces if n in include_list]
            if exclude_list:
                namespaces = [n for n in namespaces if n not in exclude_list]
            log(f"  Namespaces to scan: {namespaces}")
            # Run scans in parallel
            with ThreadPoolExecutor(max_workers=max(1, parallel)) as executor:
                futures = []
                for ns in namespaces:
                    futures.append(
                        executor.submit(trivy_scan_namespace, trivy, ctx, ns, report_type)
                    )
                if cluster_scan:
                    futures.append(
                        executor.submit(trivy_scan_cluster, trivy, ctx, report_type)
                    )
                for future in as_completed(futures):
                    try:
                        result = future.result()
                        all_scans.append(result)
                        commands_executed.append(result.get("command", ""))
                        if result.get("ok"):
                            ns_name = result.get("namespace", result.get("target", "unknown"))
                            log(f"  Completed: {ctx}/{ns_name}")
                        else:
                            log(f"  Failed: {result.get(''error'', ''Unknown error'')}")
                    except Exception as e:
                        log(f"  Scan task failed: {e}")
                        errors.append(str(e))
        # Extract findings and counts
        findings, severity_counts = extract_findings(all_scans)
        # Build summary
        successful = [s for s in all_scans if s.get("ok")]
        failed = [s for s in all_scans if not s.get("ok")]
        summary = {
            "contexts_scanned": contexts,
            "total_scans": len(all_scans),
            "successful_scans": len(successful),
            "failed_scans": len(failed),
            "total_findings": len(findings),
            "severity_counts": severity_counts,
            "critical_count": severity_counts["CRITICAL"],
            "high_count": severity_counts["HIGH"],
            "errors": errors if errors else None
        }
        log(f"Scan complete - {len(successful)}/{len(all_scans)} scans succeeded")
        log(f"Total findings: {len(findings)}")
        log(f"Severity: CRITICAL={severity_counts[''CRITICAL'']}, HIGH={severity_counts[''HIGH'']}, MEDIUM={severity_counts[''MEDIUM'']}, LOW={severity_counts[''LOW'']}")
        # Determine exit code
        exit_code = 0 if len(successful) > 0 else 1
        # Build raw output (full scan data as JSON)
        raw_output = json.dumps({
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "contexts": contexts,
            "scans": all_scans,
            "summary": summary
        }, indent=2, default=str)
        return create_result(
            findings=findings,
            summary=summary,
            raw_output=raw_output,
            console_output="\n".join(console_log),
            command_executed="; ".join(commands_executed[:5]),  # First 5 commands
            exit_code=exit_code,
            error_message="; ".join(errors) if errors and exit_code != 0 else None
        )
    except Exception as e:
        logger.error(f"Script execution failed: {e}")
        return create_result(
            findings=[],
            summary={"error": str(e)},
            console_output="\n".join(console_log),
            exit_code=1,
            error_message=str(e)
        )
# =============================================================================
# Allow standalone testing
# =============================================================================
if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format=''%(asctime)s - %(levelname)s - %(message)s'')
    # Test execution
    result = execute(
        target="minikube",
        parameters={
            "report_type": "summary",
            "parallel": 2,
            "exclude_namespaces": "kube-public,kube-system"
        },
        timeout=3600
    )
    print("\n" + "="*60)
    print("RESULT:")
    print("="*60)
    print(f"Exit Code: {result[''exit_code'']}")
    print(f"Findings: {len(result[''findings''])}")
    print(f"Summary: {json.dumps(result[''summary''], indent=2)}")
    if result[''error_message'']:
        print(f"Error: {result[''error_message'']}")
', 'Trivy Kubernetes Scanner', 'TRIVY_K8S_MULTICONTEXT', 'KUBERNETES', 'vulnerability', 'Scans Kubernetes clusters across multiple contexts using Trivy. Detects vulnerabilities, misconfigurations, and exposed secrets in workloads.', 'script', '["trivy","kubectl"]', '[{"name":"include_namespaces","label":"Include Namespaces","type":"text","hint":"Comma-separated namespaces to include (empty = all)","default":"","required":false},{"name":"exclude_namespaces","label":"Exclude Namespaces","type":"text","hint":"Namespaces to exclude from scan (comma-separated)","default":"kube-public,kube-system,kube-node-lease","required":false},{"name":"report_type","label":"Report Type","type":"select","options":["summary","all"],"default":"summary","required":false},{"name":"parallel","label":"Parallel Scans","type":"number","hint":"Number of concurrent namespace scans","default":2,"required":false},{"name":"cluster_scan","label":"Cluster-wide Scan","type":"boolean","hint":"Also run a cluster-wide scan","default":false,"required":false}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 07:40:07.436', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"trivy_k8s_multicontext","risk_level":"LOW","tool_type":"script","tools_used":["trivy","kubectl"],"name":"Trivy Kubernetes Scanner","description":"Scans Kubernetes clusters across multiple contexts using Trivy. Detects vulnerabilities, misconfigurations, and exposed secrets in workloads.","category":"KUBERNETES","parameters":[{"name":"include_namespaces","label":"Include Namespaces","type":"text","hint":"Comma-separated namespaces to include (empty = all)","default":"","required":false},{"name":"exclude_namespaces","label":"Exclude Namespaces","type":"text","hint":"Namespaces to exclude from scan (comma-separated)","default":"kube-public,kube-system,kube-node-lease","required":false},{"name":"report_type","label":"Report Type","type":"select","options":["summary","all"],"default":"summary","required":false},{"name":"parallel","label":"Parallel Scans","type":"number","hint":"Number of concurrent namespace scans","default":2,"required":false},{"name":"cluster_scan","label":"Cluster-wide Scan","type":"boolean","hint":"Also run a cluster-wide scan","default":false,"required":false}],"test_type":"vulnerability"}}', '9d647c22fa9da9ba7fb91afaf55a9472c6c0590689d2f2b84ddc480fa2653a14', 1, 'trivy_k8s_custom.py', '2026-01-07 07:39:46.294', '2026-01-07 07:40:07.434376', NULL, 'SECURITY');


--
-- Reset sequences to safe values for included tables
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);
SELECT pg_catalog.setval('public.projects_id_seq', 1, true);
SELECT pg_catalog.setval('public.environments_id_seq', 3, true);
SELECT pg_catalog.setval('public.scan_template_id_seq', 82, true);
SELECT pg_catalog.setval('public.scan_preset_id_seq', 10, true);
SELECT pg_catalog.setval('public.header_injection_presets_id_seq', 6, true);
SELECT pg_catalog.setval('public.api_payload_id_seq', 45, true);
SELECT pg_catalog.setval('public.license_id_seq', 1, true);
SELECT pg_catalog.setval('public.custom_script_id_seq', 8, true);
SELECT pg_catalog.setval('public.environment_services_id_seq', 1, false);
SELECT pg_catalog.setval('public.agent_registration_id_seq', 1, false);
SELECT pg_catalog.setval('public.agent_token_id_seq', 1, false);
SELECT pg_catalog.setval('public.alert_definition_id_seq', 1, false);
SELECT pg_catalog.setval('public.alert_instance_id_seq', 1, false);
SELECT pg_catalog.setval('public.api_scan_history_id_seq', 1, false);
SELECT pg_catalog.setval('public.api_scenario_executions_id_seq', 1, false);
SELECT pg_catalog.setval('public.api_scenario_extractions_id_seq', 1, false);
SELECT pg_catalog.setval('public.api_scenario_step_results_id_seq', 1, false);
SELECT pg_catalog.setval('public.api_scenario_steps_id_seq', 1, false);
SELECT pg_catalog.setval('public.api_scenarios_id_seq', 1, false);
SELECT pg_catalog.setval('public.audit_log_id_seq', 1, false);
SELECT pg_catalog.setval('public.auth_services_id_seq', 1, false);
SELECT pg_catalog.setval('public.finding_id_seq', 1, false);
SELECT pg_catalog.setval('public.mobile_apps_id_seq', 1, false);
SELECT pg_catalog.setval('public.mobile_inspection_results_id_seq', 1, false);
SELECT pg_catalog.setval('public.mobile_tests_id_seq', 1, false);
SELECT pg_catalog.setval('public.performance_scenarios_id_seq', 1, false);
SELECT pg_catalog.setval('public.project_applications_id_seq', 1, false);
SELECT pg_catalog.setval('public.scan_comparison_id_seq', 1, false);
SELECT pg_catalog.setval('public.scan_execution_id_seq', 1, false);
SELECT pg_catalog.setval('public.scan_group_id_seq', 1, false);
SELECT pg_catalog.setval('public.scan_group_templates_id_seq', 1, false);
SELECT pg_catalog.setval('public.scan_job_id_seq', 1, false);
SELECT pg_catalog.setval('public.scan_job_item_id_seq', 1, false);
SELECT pg_catalog.setval('public.scan_schedule_id_seq', 1, false);
SELECT pg_catalog.setval('public.ui_test_id_seq', 1, false);
SELECT pg_catalog.setval('public.ui_test_suite_id_seq', 1, false);
SELECT pg_catalog.setval('public.ui_test_suite_item_id_seq', 1, false);
