--
-- PostgreSQL database dump
--

\restrict VtHgjKLnNxCO6jtchH2Ru3vf5b2XL9hJZdwvcfRIzBCsNMKDZK6sIWkBnCBTXjq

-- Dumped from database version 14.20
-- Dumped by pg_dump version 14.20

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
-- Name: agent_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.agent_status AS ENUM (
    'IDLE',
    'BUSY',
    'OFFLINE',
    'ERROR'
);


--
-- Name: job_priority; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.job_priority AS ENUM (
    'LOW',
    'NORMAL',
    'HIGH',
    'URGENT'
);


--
-- Name: job_status; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.job_status AS ENUM (
    'PENDING',
    'CLAIMED',
    'RUNNING',
    'COMPLETED',
    'FAILED',
    'CANCELLED'
);


--
-- Name: payload_category; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.payload_category AS ENUM (
    'SQL_INJECTION',
    'XSS',
    'PATH_TRAVERSAL',
    'COMMAND_INJECTION',
    'HEADER_INJECTION',
    'AUTH_BYPASS',
    'RATE_LIMIT',
    'CUSTOM'
);


--
-- Name: risk_level; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.risk_level AS ENUM (
    'LOW',
    'MEDIUM',
    'HIGH',
    'CRITICAL'
);


--
-- Name: scan_storage_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.scan_storage_type AS ENUM (
    'DATABASE',
    'S3',
    'BOTH'
);


--
-- Name: get_latest_baseline(bigint, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_latest_baseline(p_scan_template_id bigint, p_target character varying) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_baseline_id BIGINT;
BEGIN
  SELECT id INTO v_baseline_id
  FROM scan_execution
  WHERE scan_template_id = p_scan_template_id
    AND target = p_target
    AND is_baseline = true
    AND status = 'COMPLETED'
  ORDER BY created_at DESC
  LIMIT 1;

  RETURN v_baseline_id;
END;
$$;


--
-- Name: update_agent_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_agent_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


--
-- Name: update_custom_script_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_custom_script_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


--
-- Name: update_scan_preset_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_scan_preset_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: agent_registration; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_registration (
    id bigint NOT NULL,
    agent_id character varying(100) NOT NULL,
    hostname character varying(255),
    version character varying(50),
    capabilities jsonb DEFAULT '[]'::jsonb,
    status public.agent_status DEFAULT 'OFFLINE'::public.agent_status,
    current_job_id bigint,
    last_error text,
    last_seen_at timestamp without time zone,
    registered_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    agent_version character varying(50)
);


--
-- Name: TABLE agent_registration; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.agent_registration IS 'Registered scanner agents that poll for and execute security scans';


--
-- Name: agent_registration_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_registration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_registration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_registration_id_seq OWNED BY public.agent_registration.id;


--
-- Name: agent_token; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.agent_token (
    id bigint NOT NULL,
    token_id character varying(100) NOT NULL,
    token_hash character varying(255) NOT NULL,
    customer_id character varying(100),
    environment character varying(50),
    description character varying(255),
    scans_allowed integer DEFAULT '-1'::integer,
    scans_used integer DEFAULT 0,
    is_active boolean DEFAULT true,
    expires_at timestamp without time zone,
    last_used_at timestamp without time zone,
    created_by character varying(100),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    version bigint DEFAULT 0
);


--
-- Name: TABLE agent_token; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.agent_token IS 'API tokens for scanner agent authentication with quota management';


--
-- Name: agent_token_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.agent_token_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: agent_token_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.agent_token_id_seq OWNED BY public.agent_token.id;


--
-- Name: alert_definition; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_definition (
    id bigint NOT NULL,
    alert_name character varying(100) NOT NULL,
    description text,
    scan_template_id bigint,
    alert_type character varying(20) NOT NULL,
    query_condition jsonb,
    min_changes integer DEFAULT 1,
    severity character varying(10) DEFAULT 'MEDIUM'::character varying,
    notification_channels jsonb,
    enabled boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    version bigint DEFAULT 0,
    CONSTRAINT chk_alert_definition_alert_type CHECK (((alert_type)::text = ANY (ARRAY[('DIFF_DETECTED'::character varying)::text, ('QUERY_MATCH'::character varying)::text]))),
    CONSTRAINT chk_alert_definition_severity CHECK (((severity)::text = ANY (ARRAY[('LOW'::character varying)::text, ('MEDIUM'::character varying)::text, ('HIGH'::character varying)::text, ('CRITICAL'::character varying)::text])))
);


--
-- Name: TABLE alert_definition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.alert_definition IS 'Alert rules with conditions and notification channels';


--
-- Name: COLUMN alert_definition.query_condition; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.alert_definition.query_condition IS 'JSONPath query or PostgreSQL JSON expression to match against scan results';


--
-- Name: alert_definition_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alert_definition_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_definition_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alert_definition_id_seq OWNED BY public.alert_definition.id;


--
-- Name: alert_instance; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alert_instance (
    id bigint NOT NULL,
    alert_definition_id bigint NOT NULL,
    scan_execution_id bigint NOT NULL,
    scan_comparison_id bigint,
    matched_data jsonb,
    message text,
    notifications_sent jsonb,
    status character varying(20) DEFAULT 'ACTIVE'::character varying,
    acknowledged_by character varying(100),
    acknowledged_at timestamp without time zone,
    resolved_at timestamp without time zone,
    triggered_at timestamp without time zone DEFAULT now(),
    severity character varying(20),
    version bigint DEFAULT 0,
    CONSTRAINT chk_alert_instance_status CHECK (((status)::text = ANY (ARRAY[('ACTIVE'::character varying)::text, ('ACKNOWLEDGED'::character varying)::text, ('RESOLVED'::character varying)::text, ('FALSE_POSITIVE'::character varying)::text]))),
    CONSTRAINT chk_alert_instance_time_order CHECK (((resolved_at IS NULL) OR (acknowledged_at IS NULL) OR (resolved_at > acknowledged_at)))
);


--
-- Name: TABLE alert_instance; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.alert_instance IS 'Historical record of triggered alerts';


--
-- Name: alert_instance_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alert_instance_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alert_instance_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alert_instance_id_seq OWNED BY public.alert_instance.id;


--
-- Name: api_payload; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_payload (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    category public.payload_category NOT NULL,
    payload text NOT NULL,
    description text,
    severity character varying(20) DEFAULT 'MEDIUM'::character varying,
    enabled boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    version bigint DEFAULT 0
);


--
-- Name: api_payload_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_payload_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_payload_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_payload_id_seq OWNED BY public.api_payload.id;


--
-- Name: api_scan_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_scan_history (
    id integer NOT NULL,
    user_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    target_url character varying(2000) NOT NULL,
    method character varying(10) NOT NULL,
    inject_location character varying(20),
    param_name character varying(255),
    total_requests integer DEFAULT 0,
    successful_requests integer DEFAULT 0,
    findings_count integer DEFAULT 0,
    execution_time_ms bigint,
    name character varying(255),
    description text,
    env character varying(50),
    storage_type character varying(20) DEFAULT 'DATABASE'::character varying NOT NULL,
    s3_bucket character varying(255),
    s3_key character varying(500),
    summary jsonb,
    full_result jsonb,
    config_snapshot jsonb,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    tags jsonb DEFAULT '[]'::jsonb,
    project_id bigint,
    environment_id bigint,
    service_id bigint,
    version bigint DEFAULT 0,
    target_id bigint
);


--
-- Name: TABLE api_scan_history; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.api_scan_history IS 'Stores API security scan results with flexible storage (DB/S3/Both)';


--
-- Name: COLUMN api_scan_history.summary; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scan_history.summary IS 'Always populated: findings summary, severity counts, categories';


--
-- Name: COLUMN api_scan_history.full_result; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scan_history.full_result IS 'Complete scan result including all HTTP responses (only if storage_type includes DATABASE)';


--
-- Name: COLUMN api_scan_history.config_snapshot; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scan_history.config_snapshot IS 'Snapshot of scan configuration for reproducibility';


--
-- Name: COLUMN api_scan_history.target_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scan_history.target_id IS 'Reference to the environment target scanned';


--
-- Name: api_scan_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_scan_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_scan_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_scan_history_id_seq OWNED BY public.api_scan_history.id;


--
-- Name: api_scenario_executions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_scenario_executions (
    id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    status character varying(20) NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    total_steps integer NOT NULL,
    completed_steps integer DEFAULT 0,
    failed_step_order integer,
    error_message text,
    variables_snapshot jsonb DEFAULT '{}'::jsonb,
    executed_by character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    run_name character varying(255),
    environment_id bigint,
    environment_name character varying(255),
    service_id bigint,
    service_name character varying(255),
    base_url_used character varying(500),
    tags jsonb DEFAULT '[]'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    project_id bigint,
    project_name character varying(255),
    version bigint DEFAULT 0,
    CONSTRAINT api_scenario_executions_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'RUNNING'::character varying, 'COMPLETED'::character varying, 'FAILED'::character varying, 'CANCELLED'::character varying])::text[])))
);


--
-- Name: COLUMN api_scenario_executions.project_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scenario_executions.project_id IS 'Snapshot of project ID at execution time';


--
-- Name: COLUMN api_scenario_executions.project_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scenario_executions.project_name IS 'Snapshot of project name at execution time';


--
-- Name: api_scenario_executions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_scenario_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_scenario_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_scenario_executions_id_seq OWNED BY public.api_scenario_executions.id;


--
-- Name: api_scenario_extractions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_scenario_extractions (
    id bigint NOT NULL,
    step_id bigint NOT NULL,
    variable_name character varying(100) NOT NULL,
    extraction_type character varying(20) NOT NULL,
    extraction_expression character varying(500) NOT NULL,
    default_value character varying(500),
    is_required boolean DEFAULT false,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    version bigint DEFAULT 0,
    CONSTRAINT api_scenario_extractions_extraction_type_check CHECK (((extraction_type)::text = ANY ((ARRAY['JSONPATH'::character varying, 'REGEX'::character varying, 'HEADER'::character varying])::text[])))
);


--
-- Name: api_scenario_extractions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_scenario_extractions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_scenario_extractions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_scenario_extractions_id_seq OWNED BY public.api_scenario_extractions.id;


--
-- Name: api_scenario_step_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_scenario_step_results (
    id bigint NOT NULL,
    execution_id bigint NOT NULL,
    step_id bigint NOT NULL,
    step_order integer NOT NULL,
    status character varying(20) NOT NULL,
    request_url character varying(1000),
    request_headers jsonb,
    request_body text,
    response_status integer,
    response_headers jsonb,
    response_body text,
    response_time_ms bigint,
    extracted_values jsonb DEFAULT '{}'::jsonb,
    error_message text,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    version bigint DEFAULT 0,
    CONSTRAINT api_scenario_step_results_status_check CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'RUNNING'::character varying, 'SUCCESS'::character varying, 'FAILED'::character varying, 'SKIPPED'::character varying])::text[])))
);


--
-- Name: api_scenario_step_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_scenario_step_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_scenario_step_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_scenario_step_results_id_seq OWNED BY public.api_scenario_step_results.id;


--
-- Name: api_scenario_steps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_scenario_steps (
    id bigint NOT NULL,
    scenario_id bigint NOT NULL,
    step_order integer NOT NULL,
    name character varying(255),
    description text,
    http_method character varying(10) NOT NULL,
    endpoint_path character varying(500) NOT NULL,
    request_headers jsonb DEFAULT '{}'::jsonb,
    request_body text,
    query_params jsonb DEFAULT '{}'::jsonb,
    path_params jsonb DEFAULT '{}'::jsonb,
    timeout_ms integer DEFAULT 30000,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expected_status_codes jsonb DEFAULT '[200]'::jsonb,
    response_assertions jsonb DEFAULT '[]'::jsonb,
    version bigint DEFAULT 0
);


--
-- Name: COLUMN api_scenario_steps.response_assertions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scenario_steps.response_assertions IS 'Response body assertions: type (JSONPATH/CONTAINS/REGEX), expression, operator (EQUALS/NOT_EQUALS/CONTAINS/EXISTS/NOT_EXISTS/GREATER_THAN/LESS_THAN), expectedValue';


--
-- Name: api_scenario_steps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_scenario_steps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_scenario_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_scenario_steps_id_seq OWNED BY public.api_scenario_steps.id;


--
-- Name: api_scenarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_scenarios (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    environment_id bigint,
    service_id bigint,
    swagger_url character varying(500),
    base_url character varying(500) NOT NULL,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(100),
    updated_by character varying(100),
    default_headers jsonb DEFAULT '{}'::jsonb,
    auth_config jsonb DEFAULT '{}'::jsonb,
    project_id bigint,
    version bigint DEFAULT 0
);


--
-- Name: COLUMN api_scenarios.project_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.api_scenarios.project_id IS 'Optional direct link to project (can also inherit from environment)';


--
-- Name: api_scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_scenarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_scenarios_id_seq OWNED BY public.api_scenarios.id;


--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.audit_log (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    action character varying(50) NOT NULL,
    entity_type character varying(100),
    entity_id bigint,
    user_id bigint,
    username character varying(50),
    details text,
    ip_address character varying(45),
    "timestamp" bigint NOT NULL,
    success boolean DEFAULT true NOT NULL,
    error_message character varying(500),
    user_agent character varying(255),
    version bigint DEFAULT 0
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.audit_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: custom_script; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.custom_script (
    id bigint NOT NULL,
    script_content text NOT NULL,
    name character varying(100) NOT NULL,
    tool_name character varying(50) NOT NULL,
    category character varying(50) NOT NULL,
    test_type character varying(50) NOT NULL,
    description text,
    tool_type character varying(20) DEFAULT 'SCRIPT'::character varying,
    tools_used text,
    parameters text,
    risk_level character varying(20) DEFAULT 'MEDIUM'::character varying,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    uploaded_by bigint NOT NULL,
    uploaded_by_username character varying(50),
    approved_by bigint,
    approved_by_username character varying(50),
    approved_at timestamp without time zone,
    rejection_reason text,
    validation_result text,
    checksum character varying(64),
    version integer DEFAULT 1,
    original_filename character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    script_version character varying(50),
    CONSTRAINT chk_custom_script_category CHECK (((category)::text = ANY ((ARRAY['INFRASTRUCTURE'::character varying, 'APPLICATION'::character varying, 'WEB'::character varying, 'NETWORK'::character varying, 'DATABASE'::character varying, 'PERFORMANCE'::character varying, 'KUBERNETES'::character varying, 'CLOUD'::character varying, 'CUSTOM'::character varying])::text[]))),
    CONSTRAINT chk_custom_script_risk_level CHECK (((risk_level)::text = ANY ((ARRAY['LOW'::character varying, 'MEDIUM'::character varying, 'HIGH'::character varying, 'CRITICAL'::character varying])::text[]))),
    CONSTRAINT chk_custom_script_status CHECK (((status)::text = ANY ((ARRAY['PENDING'::character varying, 'APPROVED'::character varying, 'REJECTED'::character varying, 'DISABLED'::character varying])::text[])))
);


--
-- Name: TABLE custom_script; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.custom_script IS 'User-uploaded custom Python scanner scripts';


--
-- Name: COLUMN custom_script.script_content; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.custom_script.script_content IS 'Full Python script source code';


--
-- Name: COLUMN custom_script.tool_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.custom_script.tool_name IS 'Unique identifier from SCRIPT_INFO (uppercase)';


--
-- Name: COLUMN custom_script.tools_used; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.custom_script.tools_used IS 'JSON array of external tools used (for MIX type)';


--
-- Name: COLUMN custom_script.parameters; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.custom_script.parameters IS 'JSON array of parameter definitions';


--
-- Name: COLUMN custom_script.validation_result; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.custom_script.validation_result IS 'JSON containing syntax and interface validation results';


--
-- Name: COLUMN custom_script.checksum; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.custom_script.checksum IS 'SHA-256 hash of script content for change detection';


--
-- Name: custom_script_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.custom_script_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: custom_script_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.custom_script_id_seq OWNED BY public.custom_script.id;


--
-- Name: environment_targets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.environment_targets (
    id bigint NOT NULL,
    environment_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    base_url character varying(500),
    swagger_json_url character varying(500),
    swagger_html_url character varying(500),
    metadata jsonb DEFAULT '{}'::jsonb,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    auth_config jsonb DEFAULT '{}'::jsonb,
    host character varying(255),
    port integer,
    protocol character varying(10) DEFAULT 'https'::character varying,
    swagger_path character varying(500),
    target_type character varying(50) NOT NULL,
    ip character varying(45),
    cidr character varying(50),
    home_page_url character varying(500),
    healthcheck_path character varying(255),
    db_name character varying(100),
    db_type character varying(50),
    endpoint character varying(255),
    version bigint DEFAULT 0,
    headers jsonb,
    query_params jsonb,
    crawler_config jsonb DEFAULT '{}'::jsonb
);


--
-- Name: TABLE environment_targets; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.environment_targets IS 'Targets within each environment - can be services, web apps, IPs, hosts, databases';


--
-- Name: COLUMN environment_targets.metadata; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.metadata IS 'Flexible JSON field for kubernetes info, auth config, tags, etc.';


--
-- Name: COLUMN environment_targets.auth_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.auth_config IS 'Authentication configurations keyed by type (BASIC, BEARER, API_KEY, OAUTH2_CLIENT)';


--
-- Name: COLUMN environment_targets.host; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.host IS 'Hostname or domain name (for REST_SERVICE, HOSTNAME, DATABASE, GRPC, GRAPHQL)';


--
-- Name: COLUMN environment_targets.port; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.port IS 'Port number (for REST_SERVICE, HOSTNAME, DATABASE, GRPC, GRAPHQL)';


--
-- Name: COLUMN environment_targets.protocol; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.protocol IS 'Protocol: http or https (for REST_SERVICE)';


--
-- Name: COLUMN environment_targets.swagger_path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.swagger_path IS 'Swagger/OpenAPI spec path (for REST_SERVICE)';


--
-- Name: COLUMN environment_targets.target_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.target_type IS 'Target type: REST_SERVICE, WEB_APP, IP_ADDRESS, IP_RANGE, HOSTNAME, DATABASE, GRPC, GRAPHQL';


--
-- Name: COLUMN environment_targets.ip; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.ip IS 'IP address (for IP_ADDRESS type)';


--
-- Name: COLUMN environment_targets.cidr; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.cidr IS 'CIDR notation (for IP_RANGE type, e.g., 192.168.1.0/24)';


--
-- Name: COLUMN environment_targets.home_page_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.home_page_url IS 'Home page URL (for WEB_APP type)';


--
-- Name: COLUMN environment_targets.healthcheck_path; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.healthcheck_path IS 'Health check endpoint path (for REST_SERVICE)';


--
-- Name: COLUMN environment_targets.db_name; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.db_name IS 'Database name (for DATABASE type)';


--
-- Name: COLUMN environment_targets.db_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.db_type IS 'Database type: postgres, mysql, mongodb, etc. (for DATABASE type)';


--
-- Name: COLUMN environment_targets.endpoint; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.endpoint IS 'API endpoint path (for GRAPHQL)';


--
-- Name: COLUMN environment_targets.crawler_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environment_targets.crawler_config IS 'Crawler configuration for WEB_APP targets: urlExtractionPatterns, urlDataAttributes';


--
-- Name: environment_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.environment_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: environment_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.environment_services_id_seq OWNED BY public.environment_targets.id;


--
-- Name: environments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.environments (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(100),
    updated_by character varying(100),
    auth_config jsonb DEFAULT '{}'::jsonb,
    project_id bigint,
    version bigint DEFAULT 0
);


--
-- Name: TABLE environments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.environments IS 'Stores environment configurations (dev, staging, prod, etc.)';


--
-- Name: COLUMN environments.project_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.environments.project_id IS 'Optional link to parent project (NULL for standalone environments)';


--
-- Name: environments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.environments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: environments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.environments_id_seq OWNED BY public.environments.id;


--
-- Name: header_injection_presets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.header_injection_presets (
    id bigint NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    headers jsonb DEFAULT '[]'::jsonb NOT NULL,
    is_system boolean DEFAULT false,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(100),
    version bigint DEFAULT 0
);


--
-- Name: TABLE header_injection_presets; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.header_injection_presets IS 'Saved configurations for header injection security tests';


--
-- Name: COLUMN header_injection_presets.headers; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.header_injection_presets.headers IS 'JSON array of header configs: [{headerName, payloads[], description}]';


--
-- Name: header_injection_presets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.header_injection_presets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: header_injection_presets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.header_injection_presets_id_seq OWNED BY public.header_injection_presets.id;


--
-- Name: license; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.license (
    id bigint NOT NULL,
    license_type character varying(50) DEFAULT 'EVALUATION'::character varying NOT NULL,
    activated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at timestamp without time zone NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    evaluation_days integer DEFAULT 30 NOT NULL,
    app_version character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    notes text,
    version bigint DEFAULT 0
);


--
-- Name: license_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.license_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: license_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.license_id_seq OWNED BY public.license.id;


--
-- Name: performance_scenarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.performance_scenarios (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    project_id bigint,
    environment_id bigint,
    service_id bigint,
    base_url character varying(500) NOT NULL,
    swagger_url character varying(500),
    artillery_config jsonb NOT NULL,
    test_type character varying(50) DEFAULT 'LOAD_TEST'::character varying NOT NULL,
    p95_threshold integer,
    p99_threshold integer,
    max_error_rate numeric(5,2),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    created_by character varying(100),
    updated_by character varying(100),
    version bigint DEFAULT 0,
    source_scenario_id bigint
);


--
-- Name: TABLE performance_scenarios; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.performance_scenarios IS 'Reusable Artillery performance test configurations';


--
-- Name: COLUMN performance_scenarios.artillery_config; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.performance_scenarios.artillery_config IS 'Full Artillery YAML config as JSON (phases, scenarios, ensure)';


--
-- Name: COLUMN performance_scenarios.test_type; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.performance_scenarios.test_type IS 'LOAD_TEST, STRESS_TEST, ENDURANCE_TEST, API_TEST';


--
-- Name: COLUMN performance_scenarios.p95_threshold; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.performance_scenarios.p95_threshold IS 'P95 response time threshold in milliseconds';


--
-- Name: COLUMN performance_scenarios.p99_threshold; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.performance_scenarios.p99_threshold IS 'P99 response time threshold in milliseconds';


--
-- Name: COLUMN performance_scenarios.max_error_rate; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.performance_scenarios.max_error_rate IS 'Maximum error rate percentage (e.g., 1.00 = 1%)';


--
-- Name: COLUMN performance_scenarios.source_scenario_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.performance_scenarios.source_scenario_id IS 'Reference to the API Scenario this was converted from, if any';


--
-- Name: performance_scenarios_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.performance_scenarios_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: performance_scenarios_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.performance_scenarios_id_seq OWNED BY public.performance_scenarios.id;


--
-- Name: project_applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_applications (
    id bigint NOT NULL,
    project_id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    git_provider character varying(50),
    git_url character varying(500),
    default_branch character varying(100) DEFAULT 'main'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(100),
    updated_by character varying(100),
    version bigint DEFAULT 0
);


--
-- Name: TABLE project_applications; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.project_applications IS 'Code repositories/applications within a project for tracking changes';


--
-- Name: COLUMN project_applications.git_provider; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.project_applications.git_provider IS 'Git provider: GITHUB, GITLAB, BITBUCKET, OTHER';


--
-- Name: COLUMN project_applications.git_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.project_applications.git_url IS 'URL to the git repository';


--
-- Name: COLUMN project_applications.default_branch; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.project_applications.default_branch IS 'Default branch name (main, master, develop)';


--
-- Name: project_applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_applications_id_seq OWNED BY public.project_applications.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    logo_url character varying(500),
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(100),
    updated_by character varying(100),
    version bigint DEFAULT 0
);


--
-- Name: TABLE projects; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.projects IS 'Top-level entity for organizing environments, scenarios, and scan jobs';


--
-- Name: COLUMN projects.logo_url; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.projects.logo_url IS 'URL to project logo image (optional)';


--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.projects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: scan_comparison; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_comparison (
    id bigint NOT NULL,
    baseline_scan_id bigint NOT NULL,
    current_scan_id bigint NOT NULL,
    changes_count integer NOT NULL,
    diff_patch jsonb NOT NULL,
    state character varying(20) NOT NULL,
    summary text,
    compared_at timestamp without time zone DEFAULT now(),
    version bigint DEFAULT 0,
    CONSTRAINT chk_scan_comparison_changes_count CHECK ((changes_count >= 0)),
    CONSTRAINT chk_scan_comparison_different_scans CHECK ((baseline_scan_id <> current_scan_id)),
    CONSTRAINT chk_scan_comparison_state CHECK (((state)::text = ANY (ARRAY[('MODIFIED'::character varying)::text, ('UNMODIFIED'::character varying)::text])))
);


--
-- Name: TABLE scan_comparison; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_comparison IS 'Diff results between baseline and current scans using JSON patch';


--
-- Name: COLUMN scan_comparison.diff_patch; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_comparison.diff_patch IS 'JSON Patch (RFC 6902) document showing differences';


--
-- Name: scan_comparison_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_comparison_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_comparison_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_comparison_id_seq OWNED BY public.scan_comparison.id;


--
-- Name: scan_execution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_execution (
    id bigint NOT NULL,
    scan_template_id bigint NOT NULL,
    scan_schedule_id bigint,
    target character varying(255) NOT NULL,
    parameters jsonb,
    pid bigint,
    status character varying(20) NOT NULL,
    start_time timestamp without time zone,
    end_time timestamp without time zone,
    duration_seconds integer,
    execution_result jsonb,
    raw_output text,
    exit_code integer,
    error_message text,
    is_baseline boolean DEFAULT false,
    baseline_notes text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    output_file_path character varying(500),
    executed_by character varying(100),
    scan_group_id bigint,
    process_logs text,
    process_log_file_path character varying(500),
    version bigint DEFAULT 0,
    CONSTRAINT chk_scan_execution_status CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('RUNNING'::character varying)::text, ('COMPLETED'::character varying)::text, ('FAILED'::character varying)::text, ('TIMEOUT'::character varying)::text, ('CANCELLED'::character varying)::text]))),
    CONSTRAINT chk_scan_execution_time_order CHECK (((end_time IS NULL) OR (start_time IS NULL) OR (end_time > start_time)))
);


--
-- Name: TABLE scan_execution; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_execution IS 'Individual scan executions with results stored as JSONB';


--
-- Name: COLUMN scan_execution.execution_result; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_execution.execution_result IS 'Full scan output as JSONB - schema varies by tool_name';


--
-- Name: COLUMN scan_execution.is_baseline; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_execution.is_baseline IS 'Flag indicating this is the approved "known good state" for comparison';


--
-- Name: COLUMN scan_execution.scan_group_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_execution.scan_group_id IS 'Links individual scan executions to their parent group (NULL for ad-hoc scans)';


--
-- Name: scan_execution_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_execution_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_execution_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_execution_id_seq OWNED BY public.scan_execution.id;


--
-- Name: scan_group; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_group (
    id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    environment character varying(50),
    targets jsonb NOT NULL,
    execution_mode character varying(20) DEFAULT 'SEQUENTIAL'::character varying NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    compare_to_baseline boolean DEFAULT false,
    version bigint DEFAULT 0
);


--
-- Name: TABLE scan_group; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_group IS 'Groups multiple security scanning templates and targets for coordinated penetration testing workflows';


--
-- Name: scan_group_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_group_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_group_id_seq OWNED BY public.scan_group.id;


--
-- Name: scan_group_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_group_templates (
    id bigint NOT NULL,
    scan_group_id bigint NOT NULL,
    scan_template_id bigint NOT NULL,
    execution_order integer DEFAULT 0 NOT NULL,
    version bigint DEFAULT 0
);


--
-- Name: TABLE scan_group_templates; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_group_templates IS 'Junction table linking scan groups to their templates with execution order';


--
-- Name: scan_group_templates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_group_templates_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_group_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_group_templates_id_seq OWNED BY public.scan_group_templates.id;


--
-- Name: scan_job; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_job (
    id bigint NOT NULL,
    job_id character varying(100) NOT NULL,
    customer_id character varying(100),
    environment character varying(50),
    priority character varying(20) DEFAULT 'NORMAL'::public.job_priority,
    status character varying(20) DEFAULT 'PENDING'::public.job_status,
    claimed_by character varying(100),
    claimed_at timestamp without time zone,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    result_path character varying(500),
    error_message text,
    retry_count integer DEFAULT 0,
    max_retries integer DEFAULT 3,
    next_retry_at timestamp without time zone,
    metadata jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    tag character varying(100),
    project_id bigint,
    environment_id bigint,
    target_id bigint,
    version bigint DEFAULT 0,
    performance_scenario_id bigint,
    api_scenario_id bigint,
    ui_test_id bigint,
    ui_test_suite_id bigint
);


--
-- Name: TABLE scan_job; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_job IS 'Job queue for scanner agents with priority and retry support';


--
-- Name: COLUMN scan_job.project_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_job.project_id IS 'Optional link to project for organizing scan jobs';


--
-- Name: COLUMN scan_job.environment_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_job.environment_id IS 'Optional link to environment where scan target is deployed';


--
-- Name: COLUMN scan_job.target_id; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_job.target_id IS 'Optional link to target being scanned';


--
-- Name: scan_job_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_job_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_job_id_seq OWNED BY public.scan_job.id;


--
-- Name: scan_job_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_job_item (
    id bigint NOT NULL,
    scan_job_id bigint NOT NULL,
    scan_id character varying(100) NOT NULL,
    scan_template_id bigint,
    tool_name character varying(50) NOT NULL,
    template_name character varying(100),
    target character varying(500) NOT NULL,
    parameters jsonb DEFAULT '{}'::jsonb,
    timeout_seconds integer DEFAULT 3600,
    status character varying(20) DEFAULT 'PENDING'::public.job_status,
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    duration_seconds integer,
    exit_code integer,
    error_message text,
    findings jsonb DEFAULT '[]'::jsonb,
    summary jsonb DEFAULT '{}'::jsonb,
    raw_output text,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    html_report text,
    console_output text,
    report_output text,
    command_executed text,
    version bigint DEFAULT 0
);


--
-- Name: TABLE scan_job_item; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_job_item IS 'Individual scans within a job, linked to scan templates';


--
-- Name: scan_job_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_job_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_job_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_job_item_id_seq OWNED BY public.scan_job_item.id;


--
-- Name: scan_preset; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_preset (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    scan_template_id bigint NOT NULL,
    target_pattern character varying(500),
    parameters text NOT NULL,
    tags text,
    category character varying(100),
    created_by character varying(100) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_used_at timestamp without time zone,
    is_public boolean DEFAULT false,
    is_favorite boolean DEFAULT false,
    execution_count integer DEFAULT 0,
    version bigint DEFAULT 0
);


--
-- Name: TABLE scan_preset; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_preset IS 'Stores reusable scan configurations with tags and descriptions';


--
-- Name: COLUMN scan_preset.target_pattern; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_preset.target_pattern IS 'Target URL or ${TARGET} placeholder for dynamic targets';


--
-- Name: COLUMN scan_preset.parameters; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_preset.parameters IS 'JSON string of scan parameters matching scan_execution format';


--
-- Name: COLUMN scan_preset.tags; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_preset.tags IS 'Comma-separated tags for categorization and filtering';


--
-- Name: COLUMN scan_preset.is_public; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_preset.is_public IS 'If true, preset is visible to all users; if false, only creator can see it';


--
-- Name: COLUMN scan_preset.execution_count; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_preset.execution_count IS 'Number of times this preset has been executed';


--
-- Name: scan_preset_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_preset_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_preset_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_preset_id_seq OWNED BY public.scan_preset.id;


--
-- Name: scan_schedule; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_schedule (
    id bigint NOT NULL,
    scan_template_id bigint NOT NULL,
    cron_expression character varying(100) NOT NULL,
    enabled boolean DEFAULT true,
    targets jsonb NOT NULL,
    parameters jsonb,
    execution_mode character varying(20) DEFAULT 'SEQUENTIAL'::character varying,
    batch_size integer DEFAULT 10,
    compare_to_baseline boolean DEFAULT false,
    last_run_at timestamp without time zone,
    next_run_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    version bigint DEFAULT 0,
    CONSTRAINT chk_scan_schedule_batch_size CHECK (((batch_size IS NULL) OR (batch_size > 0))),
    CONSTRAINT chk_scan_schedule_execution_mode CHECK (((execution_mode)::text = ANY (ARRAY[('SEQUENTIAL'::character varying)::text, ('PARALLEL'::character varying)::text, ('BATCH'::character varying)::text])))
);


--
-- Name: TABLE scan_schedule; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_schedule IS 'Scheduled scan jobs with cron expressions';


--
-- Name: scan_schedule_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_schedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_schedule_id_seq OWNED BY public.scan_schedule.id;


--
-- Name: scan_template; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.scan_template (
    id bigint NOT NULL,
    category character varying(50) NOT NULL,
    test_type character varying(50) NOT NULL,
    tool_name character varying(50) NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    command_template text NOT NULL,
    timeout_seconds integer DEFAULT 7200,
    output_format character varying(20),
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    parameter_schema jsonb,
    risk_level character varying(20) DEFAULT 'LOW'::public.risk_level,
    version bigint DEFAULT 0,
    CONSTRAINT chk_scan_template_timeout CHECK (((timeout_seconds IS NULL) OR (timeout_seconds > 0)))
);


--
-- Name: TABLE scan_template; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.scan_template IS 'Scan templates including NMAP NSE script profiles with risk classifications';


--
-- Name: COLUMN scan_template.risk_level; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.scan_template.risk_level IS 'Risk level of executing this scan: LOW (safe), MEDIUM (active but non-destructive), HIGH (may trigger alerts/locks), CRITICAL (may crash services)';


--
-- Name: scan_template_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.scan_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: scan_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.scan_template_id_seq OWNED BY public.scan_template.id;


--
-- Name: ui_test; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ui_test (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    project_id bigint,
    yaml_content text NOT NULL,
    page_objects text,
    tags text,
    status character varying(50) DEFAULT 'ACTIVE'::character varying,
    created_by character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    version integer DEFAULT 0,
    group_name character varying(100),
    feature character varying(255),
    tested_version character varying(100)
);


--
-- Name: ui_test_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ui_test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ui_test_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ui_test_id_seq OWNED BY public.ui_test.id;


--
-- Name: ui_test_suite; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ui_test_suite (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    project_id bigint NOT NULL,
    reuse_browser boolean DEFAULT false,
    status character varying(50) DEFAULT 'ACTIVE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_by character varying(100),
    updated_by character varying(100),
    version integer DEFAULT 0
);


--
-- Name: ui_test_suite_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ui_test_suite_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ui_test_suite_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ui_test_suite_id_seq OWNED BY public.ui_test_suite.id;


--
-- Name: ui_test_suite_item; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ui_test_suite_item (
    id bigint NOT NULL,
    suite_id bigint NOT NULL,
    ui_test_id bigint NOT NULL,
    sort_order integer DEFAULT 0,
    weight integer DEFAULT 1,
    is_active boolean DEFAULT true,
    target_id bigint
);


--
-- Name: ui_test_suite_item_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ui_test_suite_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ui_test_suite_item_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ui_test_suite_item_id_seq OWNED BY public.ui_test_suite_item.id;


--
-- Name: user_roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_roles (
    user_id bigint NOT NULL,
    role character varying(50) NOT NULL,
    version bigint DEFAULT 0,
    CONSTRAINT chk_user_roles_role CHECK (((role)::text = ANY (ARRAY[('VIEWER'::character varying)::text, ('ANALYST'::character varying)::text, ('ADMIN'::character varying)::text])))
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    full_name character varying(100),
    enabled boolean DEFAULT true NOT NULL,
    account_locked boolean DEFAULT false,
    last_login bigint,
    version bigint DEFAULT 0
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: agent_registration id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_registration ALTER COLUMN id SET DEFAULT nextval('public.agent_registration_id_seq'::regclass);


--
-- Name: agent_token id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_token ALTER COLUMN id SET DEFAULT nextval('public.agent_token_id_seq'::regclass);


--
-- Name: alert_definition id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_definition ALTER COLUMN id SET DEFAULT nextval('public.alert_definition_id_seq'::regclass);


--
-- Name: alert_instance id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_instance ALTER COLUMN id SET DEFAULT nextval('public.alert_instance_id_seq'::regclass);


--
-- Name: api_payload id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_payload ALTER COLUMN id SET DEFAULT nextval('public.api_payload_id_seq'::regclass);


--
-- Name: api_scan_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history ALTER COLUMN id SET DEFAULT nextval('public.api_scan_history_id_seq'::regclass);


--
-- Name: api_scenario_executions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_executions ALTER COLUMN id SET DEFAULT nextval('public.api_scenario_executions_id_seq'::regclass);


--
-- Name: api_scenario_extractions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_extractions ALTER COLUMN id SET DEFAULT nextval('public.api_scenario_extractions_id_seq'::regclass);


--
-- Name: api_scenario_step_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_step_results ALTER COLUMN id SET DEFAULT nextval('public.api_scenario_step_results_id_seq'::regclass);


--
-- Name: api_scenario_steps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_steps ALTER COLUMN id SET DEFAULT nextval('public.api_scenario_steps_id_seq'::regclass);


--
-- Name: api_scenarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenarios ALTER COLUMN id SET DEFAULT nextval('public.api_scenarios_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: custom_script id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_script ALTER COLUMN id SET DEFAULT nextval('public.custom_script_id_seq'::regclass);


--
-- Name: environment_targets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environment_targets ALTER COLUMN id SET DEFAULT nextval('public.environment_services_id_seq'::regclass);


--
-- Name: environments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments ALTER COLUMN id SET DEFAULT nextval('public.environments_id_seq'::regclass);


--
-- Name: header_injection_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.header_injection_presets ALTER COLUMN id SET DEFAULT nextval('public.header_injection_presets_id_seq'::regclass);


--
-- Name: license id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license ALTER COLUMN id SET DEFAULT nextval('public.license_id_seq'::regclass);


--
-- Name: performance_scenarios id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios ALTER COLUMN id SET DEFAULT nextval('public.performance_scenarios_id_seq'::regclass);


--
-- Name: project_applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_applications ALTER COLUMN id SET DEFAULT nextval('public.project_applications_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: scan_comparison id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_comparison ALTER COLUMN id SET DEFAULT nextval('public.scan_comparison_id_seq'::regclass);


--
-- Name: scan_execution id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_execution ALTER COLUMN id SET DEFAULT nextval('public.scan_execution_id_seq'::regclass);


--
-- Name: scan_group id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group ALTER COLUMN id SET DEFAULT nextval('public.scan_group_id_seq'::regclass);


--
-- Name: scan_group_templates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group_templates ALTER COLUMN id SET DEFAULT nextval('public.scan_group_templates_id_seq'::regclass);


--
-- Name: scan_job id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job ALTER COLUMN id SET DEFAULT nextval('public.scan_job_id_seq'::regclass);


--
-- Name: scan_job_item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job_item ALTER COLUMN id SET DEFAULT nextval('public.scan_job_item_id_seq'::regclass);


--
-- Name: scan_preset id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_preset ALTER COLUMN id SET DEFAULT nextval('public.scan_preset_id_seq'::regclass);


--
-- Name: scan_schedule id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_schedule ALTER COLUMN id SET DEFAULT nextval('public.scan_schedule_id_seq'::regclass);


--
-- Name: scan_template id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_template ALTER COLUMN id SET DEFAULT nextval('public.scan_template_id_seq'::regclass);


--
-- Name: ui_test id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test ALTER COLUMN id SET DEFAULT nextval('public.ui_test_id_seq'::regclass);


--
-- Name: ui_test_suite id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite ALTER COLUMN id SET DEFAULT nextval('public.ui_test_suite_id_seq'::regclass);


--
-- Name: ui_test_suite_item id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite_item ALTER COLUMN id SET DEFAULT nextval('public.ui_test_suite_item_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: agent_registration; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: agent_token; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: alert_definition; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.alert_definition VALUES (1, 'SSH Port Exposed', 'Alert when SSH port 22 is detected as open', NULL, 'QUERY_MATCH', '{"jsonpath": "$.hosts[*].ports[?(@.port == 22 && @.state == ''open'')]"}', 1, 'HIGH', '["SLACK", "JIRA"]', true, '2025-12-19 08:05:16.396371', '2025-12-19 08:05:16.396371', 0);
INSERT INTO public.alert_definition VALUES (2, 'Network Changes Detected', 'Alert when any changes are detected in network scan', NULL, 'DIFF_DETECTED', NULL, 1, 'MEDIUM', '["SLACK"]', true, '2025-12-19 08:05:16.396371', '2025-12-19 08:05:16.396371', 0);


--
-- Data for Name: alert_instance; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: api_payload; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.api_payload VALUES (1, 'Basic OR Bypass', 'SQL_INJECTION', ''' OR ''1''=''1', 'Basic SQL injection OR bypass', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (2, 'OR 1=1', 'SQL_INJECTION', ''' OR 1=1--', 'Classic OR 1=1 injection', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (3, 'OR 1=1 Hash', 'SQL_INJECTION', ''' OR 1=1#', 'OR 1=1 with hash comment', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (4, 'Union Select', 'SQL_INJECTION', ''' UNION SELECT NULL--', 'Union-based injection probe', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (5, 'Union Select Multiple', 'SQL_INJECTION', ''' UNION SELECT NULL,NULL,NULL--', 'Union with multiple columns', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (6, 'Time-based Blind', 'SQL_INJECTION', ''' OR SLEEP(5)--', 'Time-based blind SQLi', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (7, 'Error-based', 'SQL_INJECTION', ''' AND 1=CONVERT(int,(SELECT @@version))--', 'Error-based SQLi for MSSQL', 'HIGH', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (8, 'Stacked Query', 'SQL_INJECTION', '''; DROP TABLE users--', 'Stacked query injection', 'CRITICAL', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (9, 'Boolean Blind True', 'SQL_INJECTION', ''' AND 1=1--', 'Boolean blind - true condition', 'MEDIUM', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (10, 'Boolean Blind False', 'SQL_INJECTION', ''' AND 1=2--', 'Boolean blind - false condition', 'MEDIUM', true, '2026-01-08 07:28:33.028052', '2026-01-08 07:28:33.028052', 0);
INSERT INTO public.api_payload VALUES (11, 'Basic Script', 'XSS', '<script>alert(1)</script>', 'Basic XSS script tag', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (12, 'IMG Onerror', 'XSS', '<img src=x onerror=alert(1)>', 'XSS via img onerror', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (13, 'SVG Onload', 'XSS', '<svg onload=alert(1)>', 'XSS via SVG onload', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (14, 'Body Onload', 'XSS', '<body onload=alert(1)>', 'XSS via body onload', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (15, 'Event Handler', 'XSS', '" onmouseover="alert(1)"', 'XSS via event handler injection', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (16, 'JavaScript URI', 'XSS', 'javascript:alert(1)', 'JavaScript protocol handler', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (17, 'Data URI', 'XSS', 'data:text/html,<script>alert(1)</script>', 'XSS via data URI', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (18, 'Encoded Script', 'XSS', '%3Cscript%3Ealert(1)%3C/script%3E', 'URL encoded XSS', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (19, 'Double Encoded', 'XSS', '%253Cscript%253Ealert(1)%253C/script%253E', 'Double URL encoded XSS', 'MEDIUM', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (20, 'Template Injection', 'XSS', '{{constructor.constructor(''alert(1)'')()}}', 'Template injection XSS', 'HIGH', true, '2026-01-08 07:28:33.030045', '2026-01-08 07:28:33.030045', 0);
INSERT INTO public.api_payload VALUES (21, 'Basic Traversal', 'PATH_TRAVERSAL', '../../../etc/passwd', 'Basic path traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (22, 'Windows Traversal', 'PATH_TRAVERSAL', '..\\..\\..\\windows\\system32\\config\\sam', 'Windows path traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (23, 'Encoded Traversal', 'PATH_TRAVERSAL', '..%2F..%2F..%2Fetc%2Fpasswd', 'URL encoded traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (24, 'Double Encoded', 'PATH_TRAVERSAL', '..%252F..%252F..%252Fetc%252Fpasswd', 'Double encoded traversal', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (25, 'Null Byte', 'PATH_TRAVERSAL', '../../../etc/passwd%00.jpg', 'Null byte injection', 'HIGH', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (26, 'UTF-8 Encoded', 'PATH_TRAVERSAL', '..%c0%af..%c0%af..%c0%afetc/passwd', 'UTF-8 encoded traversal', 'MEDIUM', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (27, 'Absolute Path', 'PATH_TRAVERSAL', '/etc/passwd', 'Absolute path injection', 'MEDIUM', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (28, 'Dot Dot Slash Variations', 'PATH_TRAVERSAL', '....//....//....//etc/passwd', 'Filter bypass variation', 'MEDIUM', true, '2026-01-08 07:28:33.031353', '2026-01-08 07:28:33.031353', 0);
INSERT INTO public.api_payload VALUES (29, 'Semicolon Chain', 'COMMAND_INJECTION', '; ls -la', 'Command chaining with semicolon', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (30, 'Pipe Chain', 'COMMAND_INJECTION', '| cat /etc/passwd', 'Command piping', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (31, 'Backtick Exec', 'COMMAND_INJECTION', '`id`', 'Backtick command execution', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (32, 'Dollar Paren', 'COMMAND_INJECTION', '$(id)', 'Dollar-paren command execution', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (33, 'AND Chain', 'COMMAND_INJECTION', '&& cat /etc/passwd', 'AND command chaining', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (34, 'OR Chain', 'COMMAND_INJECTION', '|| cat /etc/passwd', 'OR command chaining', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (35, 'Newline Injection', 'COMMAND_INJECTION', '\nid', 'Newline command injection', 'HIGH', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (36, 'Windows Command', 'COMMAND_INJECTION', '& dir', 'Windows command injection', 'CRITICAL', true, '2026-01-08 07:28:33.032492', '2026-01-08 07:28:33.032492', 0);
INSERT INTO public.api_payload VALUES (37, 'CRLF Injection', 'HEADER_INJECTION', '\r\nX-Injected: true', 'CRLF header injection', 'HIGH', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload VALUES (38, 'Host Override', 'HEADER_INJECTION', 'evil.com', 'Host header injection', 'MEDIUM', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload VALUES (39, 'X-Forwarded-For', 'HEADER_INJECTION', '127.0.0.1', 'IP spoofing via X-Forwarded-For', 'MEDIUM', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload VALUES (40, 'X-Forwarded-Host', 'HEADER_INJECTION', 'evil.com', 'Host spoofing via X-Forwarded-Host', 'MEDIUM', true, '2026-01-08 07:28:33.033437', '2026-01-08 07:28:33.033437', 0);
INSERT INTO public.api_payload VALUES (41, 'Empty Token', 'AUTH_BYPASS', '', 'Empty authentication token', 'HIGH', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload VALUES (42, 'Null Token', 'AUTH_BYPASS', 'null', 'Null string token', 'HIGH', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload VALUES (43, 'Admin Role', 'AUTH_BYPASS', '{"role":"admin"}', 'Role escalation attempt', 'CRITICAL', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload VALUES (44, 'JWT None Alg', 'AUTH_BYPASS', 'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9.', 'JWT with none algorithm', 'CRITICAL', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);
INSERT INTO public.api_payload VALUES (45, 'Basic Auth Bypass', 'AUTH_BYPASS', 'Basic YWRtaW46YWRtaW4=', 'Basic auth with admin:admin', 'HIGH', true, '2026-01-08 07:28:33.034207', '2026-01-08 07:28:33.034207', 0);


--
-- Data for Name: api_scenario_extractions; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.api_scenario_extractions VALUES (3, 16, 'petId', 'JSONPATH', '$.id', NULL, true, NULL, '2026-01-10 17:07:08.883265', 0);
INSERT INTO public.api_scenario_extractions VALUES (5, 30, 'petId', 'JSONPATH', '$.id', NULL, true, 'Extract created pet ID', '2026-01-11 02:39:32.911473', 0);
INSERT INTO public.api_scenario_extractions VALUES (6, 38, 'petId', 'JSONPATH', '$.id', 'fake', false, NULL, '2026-01-17 07:01:02.765965', 0);


--
-- Data for Name: api_scenario_steps; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.api_scenario_steps VALUES (16, 8, 1, 'Create Pet', NULL, 'POST', '/pet', '{"Accept": "application/json", "Content-Type": "application/json"}', '{"id": 98765, "name": "Fluffy", "photoUrls": ["http://example.com/photo.jpg"], "status": "available"}', NULL, NULL, 30000, true, '2026-01-10 17:07:08.878225', '2026-01-10 17:07:08.878229', '[200]', '[{"type": "JSONPATH", "operator": "EXISTS", "expression": "$.id", "expectedValue": ""}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Fluffy"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "available"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (17, 8, 2, 'Get Created Pet', NULL, 'GET', '/pet/{petId}', '{"Accept": "application/json"}', NULL, NULL, '{"petId": "{{petId}}"}', 30000, true, '2026-01-10 17:07:08.887142', '2026-01-10 17:07:08.887145', '[200]', '[{"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Fluffy"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "available"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (18, 8, 3, 'Update Pet Status', NULL, 'PUT', '/pet', '{"Accept": "application/json", "Content-Type": "application/json"}', '{"id": {{petId}}, "name": "Fluffy Updated", "photoUrls": ["http://example.com/photo.jpg"], "status": "sold"}', NULL, NULL, 30000, true, '2026-01-10 17:07:08.890719', '2026-01-10 17:07:08.890724', '[200]', '[{"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Fluffy Updated"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "sold"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (19, 8, 4, 'Verify Updated Pet', NULL, 'GET', '/pet/{petId}', '{"Accept": "application/json"}', NULL, NULL, '{"petId": "{{petId}}"}', 30000, true, '2026-01-10 17:07:08.893438', '2026-01-10 17:07:08.89344', '[200]', '[{"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Fluffy Updated"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "sold"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (20, 9, 1, 'addPet', 'Add a new pet to the store.', 'POST', '/pet', '{"Content-Type": "application/json"}', '{
  "id": 10,
  "name": "doggie",
  "category": {
    "id": 1,
    "name": "Dogs"
  },
  "photoUrls": [
    "string"
  ],
  "tags": [
    {
      "id": 0,
      "name": "string"
    }
  ],
  "status": "available"
}', '{}', '{}', 30000, true, '2026-01-11 02:18:21.920465', '2026-01-11 02:18:21.920468', '[200]', '[]', 0);
INSERT INTO public.api_scenario_steps VALUES (21, 9, 2, 'findPetsByStatus', 'Finds Pets by status.', 'GET', '/pet/findByStatus', '{}', '', '{}', '{}', 30000, true, '2026-01-11 02:18:21.922543', '2026-01-11 02:18:21.922546', '[200]', '[]', 0);
INSERT INTO public.api_scenario_steps VALUES (22, 9, 3, 'updatePet', 'Update an existing pet.', 'PUT', '/pet', '{"Content-Type": "application/json"}', '{
  "id": 10,
  "name": "doggie",
  "category": {
    "id": 1,
    "name": "Dogs"
  },
  "photoUrls": [
    "string"
  ],
  "tags": [
    {
      "id": 0,
      "name": "string"
    }
  ],
  "status": "available"
}', '{}', '{}', 30000, true, '2026-01-11 02:18:21.923615', '2026-01-11 02:18:21.923618', '[200]', '[]', 0);
INSERT INTO public.api_scenario_steps VALUES (30, 11, 1, 'Create New Pet', 'Create a new pet with unique ID', 'POST', '/pet', '{"Accept": "application/json", "Content-Type": "application/json"}', '{
  "id": 77889900,
  "name": "Demo Dog",
  "category": {
    "id": 1,
    "name": "Dogs"
  },
  "photoUrls": [
    "https://example.com/dog.jpg"
  ],
  "tags": [
    {
      "id": 1,
      "name": "demo"
    }
  ],
  "status": "available"
}', '{}', '{}', 30000, true, '2026-01-11 02:39:32.910378', '2026-01-11 02:39:32.91038', '[200]', '[{"type": "JSONPATH", "operator": "EXISTS", "expression": "$.id", "expectedValue": ""}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Demo Dog"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "available"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (31, 11, 2, 'Get Pet by ID', 'Retrieve the pet we just created using extracted ID', 'GET', '/pet/{{petId}}', '{"Accept": "application/json"}', '', '{}', '{}', 30000, true, '2026-01-11 02:39:32.912171', '2026-01-11 02:39:32.912172', '[200]', '[{"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Demo Dog"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "available"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (32, 11, 3, 'Find Pets by Status', 'Search for available pets', 'GET', '/pet/findByStatus', '{"Accept": "application/json"}', '', '{"status": "available"}', '{}', 30000, true, '2026-01-11 02:39:32.913239', '2026-01-11 02:39:32.91324', '[200]', '[]', 0);
INSERT INTO public.api_scenario_steps VALUES (33, 11, 4, 'Update Pet Status', 'Update the pet status from available to sold', 'PUT', '/pet', '{"Accept": "application/json", "Content-Type": "application/json"}', '{
  "id": {{petId}},
  "name": "Demo Dog Updated",
  "category": {
    "id": 1,
    "name": "Dogs"
  },
  "photoUrls": [
    "https://example.com/dog-updated.jpg"
  ],
  "tags": [
    {
      "id": 1,
      "name": "demo"
    },
    {
      "id": 2,
      "name": "updated"
    }
  ],
  "status": "sold"
}', '{}', '{}', 30000, true, '2026-01-11 02:39:32.914272', '2026-01-11 02:39:32.914274', '[200]', '[{"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Demo Dog Updated"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "sold"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (34, 11, 5, 'Verify Pet Update', 'Get the pet again to verify the update was applied', 'GET', '/pet/{{petId}}', '{"Accept": "application/json"}', '', '{}', '{}', 30000, true, '2026-01-11 02:39:32.915498', '2026-01-11 02:39:32.915499', '[200]', '[{"type": "JSONPATH", "operator": "EQUALS", "expression": "$.name", "expectedValue": "Demo Dog Updated"}, {"type": "JSONPATH", "operator": "EQUALS", "expression": "$.status", "expectedValue": "sold"}]', 0);
INSERT INTO public.api_scenario_steps VALUES (35, 11, 6, 'Delete Pet', 'Delete the pet we created', 'DELETE', '/pet/{{petId}}', '{"Accept": "application/json"}', '', '{}', '{}', 30000, true, '2026-01-11 02:39:32.916801', '2026-01-11 02:39:32.916802', '[200]', '[]', 0);
INSERT INTO public.api_scenario_steps VALUES (36, 11, 7, 'Verify Pet Deleted', 'Try to get the deleted pet - should return 404', 'GET', '/pet/{{petId}}', '{"Accept": "application/json"}', '', '{}', '{}', 30000, true, '2026-01-11 02:39:32.917872', '2026-01-11 02:39:32.917873', '[404]', '[]', 0);
INSERT INTO public.api_scenario_steps VALUES (38, 13, 1, 'addPet', 'Add a new pet to the store', 'POST', '/pet', '{"Content-Type": "application/json"}', '{
  "id": 0,
  "category": {
    "id": 0,
    "name": "string"
  },
  "name": "doggie",
  "photoUrls": [
    "string"
  ],
  "tags": [
    {
      "id": 0,
      "name": "string"
    }
  ],
  "status": "available"
}', '{}', '{}', 30000, true, '2026-01-17 07:01:02.764169', '2026-01-17 07:01:02.76417', '[200]', '[]', 0);
INSERT INTO public.api_scenario_steps VALUES (39, 13, 2, 'getPetById', 'Find pet by ID', 'GET', '/pet/{petId}', '{}', '', '{}', '{"petId": "{{petId}}"}', 30000, true, '2026-01-17 07:01:02.76726', '2026-01-17 07:01:02.767261', '[200]', '[]', 0);


--
-- Data for Name: api_scenarios; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.api_scenarios VALUES (8, 'Petstore v2 CRUD Test', 'Test POST, GET, PUT flow with v2 API', NULL, NULL, NULL, 'https://petstore.swagger.io/v2', true, '2026-01-10 17:07:08.874117', '2026-01-11 02:19:44.278672', 'admin', 'admin', '{"Accept": "application/json"}', '{"apiKey": "special-key", "authType": "NONE", "clientId": "admin", "password": "admin123", "username": "admin", "apiKeyName": "admin", "apiKeyValue": "admin123", "apiKeyHeader": "api_key", "clientSecret": "admin123"}', NULL, 0);
INSERT INTO public.api_scenarios VALUES (9, 'demo', 'test', 1, 1, 'https://petstore3.swagger.io/api/v3/openapi.json', 'https://petstore3.swagger.io/api/v3', true, '2026-01-11 02:18:21.918387', '2026-01-11 02:18:21.91839', 'admin', 'admin', '{}', '{"OAUTH2_CLIENT": {"www": "www"}}', 1, 0);
INSERT INTO public.api_scenarios VALUES (11, 'Pet Store v2 Complete CRUD Demo', 'Demonstrates full CRUD operations on the Pet Store v2 API: Create, Read, Update, Delete with variable extraction and assertions', 1, 1, NULL, 'https://petstore.swagger.io/v2', true, '2026-01-11 02:39:32.909172', '2026-01-11 02:39:32.909174', 'admin', 'admin', '{"Accept": "application/json"}', '{}', 1, 0);
INSERT INTO public.api_scenarios VALUES (13, 'Test1', 'testing', 1, 1, 'https://petstore.swagger.io/v2/swagger.json', 'https://petstore.swagger.io/v2', true, '2026-01-17 07:01:02.761833', '2026-01-17 07:01:02.761834', 'admin', 'admin', '{}', '{}', 1, 0);


--
-- Data for Name: custom_script; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.custom_script VALUES (4, '"""
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
', 'Nmap Vulnerability Scanner', 'NMAP_VULN_CUSTOM', 'NETWORK', 'vulnerability', 'Performs network vulnerability scanning using nmap with NSE vulnerability scripts', 'SCRIPT', '["nmap"]', '[{"name":"scan_type","type":"select","options":["quick","standard","deep"],"default":"standard","description":"Scan intensity level"},{"name":"ports","type":"string","default":"1-1000","description":"Port range to scan (e.g., 1-1000, 22,80,443)"},{"name":"scripts","type":"string","default":"vuln","description":"NSE script categories to run (e.g., vuln, default, safe)"}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 06:23:59.927', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"NMAP_VULN_CUSTOM","risk_level":"LOW","tools_used":["nmap"],"name":"Nmap Vulnerability Scanner","description":"Performs network vulnerability scanning using nmap with NSE vulnerability scripts","category":"NETWORK","parameters":[{"name":"scan_type","type":"select","options":["quick","standard","deep"],"default":"standard","description":"Scan intensity level"},{"name":"ports","type":"string","default":"1-1000","description":"Port range to scan (e.g., 1-1000, 22,80,443)"},{"name":"scripts","type":"string","default":"vuln","description":"NSE script categories to run (e.g., vuln, default, safe)"}],"test_type":"vulnerability"}}', 'edda2ac28c1e322dd8586ee553dfab3ed951c10f63aac2224048d84dd6f54c2a', 1, 'nmap_vuln_scan.py', '2026-01-07 06:23:48.017', '2026-01-07 06:23:59.92479', NULL);
INSERT INTO public.custom_script VALUES (6, '"""
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
', 'SQLMap Injection Scanner', 'SQLMAP_INJECT_CUSTOM', 'APPLICATION', 'vulnerability', 'Performs automated SQL injection detection and exploitation testing using sqlmap', 'SCRIPT', '["sqlmap"]', '[{"name":"method","type":"select","options":["GET","POST"],"default":"GET","description":"HTTP method to use"},{"name":"data","type":"string","default":"","description":"POST data (e.g., id=1&name=test)"},{"name":"level","type":"select","options":["1","2","3","4","5"],"default":"1","description":"Level of tests to perform (1-5)"},{"name":"risk","type":"select","options":["1","2","3"],"default":"1","description":"Risk of tests to perform (1-3)"},{"name":"dbms","type":"select","options":["auto","mysql","postgresql","mssql","oracle","sqlite"],"default":"auto","description":"Target database management system"}]', 'MEDIUM', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 06:25:28.469', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"SQLMAP_INJECT_CUSTOM","risk_level":"MEDIUM","tools_used":["sqlmap"],"name":"SQLMap Injection Scanner","description":"Performs automated SQL injection detection and exploitation testing using sqlmap","category":"APPLICATION","parameters":[{"name":"method","type":"select","options":["GET","POST"],"default":"GET","description":"HTTP method to use"},{"name":"data","type":"string","default":"","description":"POST data (e.g., id=1&name=test)"},{"name":"level","type":"select","options":["1","2","3","4","5"],"default":"1","description":"Level of tests to perform (1-5)"},{"name":"risk","type":"select","options":["1","2","3"],"default":"1","description":"Risk of tests to perform (1-3)"},{"name":"dbms","type":"select","options":["auto","mysql","postgresql","mssql","oracle","sqlite"],"default":"auto","description":"Target database management system"}],"test_type":"vulnerability"}}', 'b940362b847688e0413b0b24ece33349e2ae8457bd9aa650742bae2ac1ead86c', 1, 'sqlmap_injection_scan.py', '2026-01-07 06:25:28.38', '2026-01-07 06:25:28.46791', NULL);
INSERT INTO public.custom_script VALUES (5, '"""
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
', 'Nikto Web Vulnerability Scanner', 'NIKTO_WEB_CUSTOM', 'WEB', 'vulnerability', 'Performs comprehensive web server vulnerability scanning using nikto', 'SCRIPT', '["nikto"]', '[{"name":"ssl","type":"boolean","default":false,"description":"Use SSL/HTTPS for connection"},{"name":"port","type":"number","default":80,"description":"Target port (default 80, or 443 for SSL)"},{"name":"tuning","type":"select","options":["1","2","3","4","5","6","7","8","9","x"],"default":"x","description":"Scan tuning (1=files, 2=misconfig, 3=info, x=all)"},{"name":"maxtime","type":"number","default":3600,"description":"Maximum scan time in seconds"}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-08 07:37:28.634', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"NIKTO_WEB_CUSTOM","risk_level":"LOW","tools_used":["nikto"],"name":"Nikto Web Vulnerability Scanner","description":"Performs comprehensive web server vulnerability scanning using nikto","category":"WEB","parameters":[{"name":"ssl","type":"boolean","default":false,"description":"Use SSL/HTTPS for connection"},{"name":"port","type":"number","default":80,"description":"Target port (default 80, or 443 for SSL)"},{"name":"tuning","type":"select","options":["1","2","3","4","5","6","7","8","9","x"],"default":"x","description":"Scan tuning (1=files, 2=misconfig, 3=info, x=all)"},{"name":"maxtime","type":"number","default":3600,"description":"Maximum scan time in seconds"}],"test_type":"vulnerability"}}', 'a2e6cbd0a66f698e72bb4e64364d38b1bdadc6ba37a16cdfc5fff976207e1903', 2, 'nikto_web_scan.py', '2026-01-07 06:24:53.512', '2026-01-08 07:37:28.63321', NULL);
INSERT INTO public.custom_script VALUES (7, '"""
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
', 'Nuclei Template Scanner', 'NUCLEI_TEMPLATE_CUSTOM', 'APPLICATION', 'vulnerability', 'Performs fast and customizable vulnerability scanning using nuclei templates', 'SCRIPT', '["nuclei"]', '[{"name":"severity","type":"select","options":["info","low","medium","high","critical","all"],"default":"all","description":"Minimum severity level to report"},{"name":"tags","type":"string","default":"","description":"Template tags to include (e.g., cve,rce,lfi)"},{"name":"exclude_tags","type":"string","default":"dos","description":"Template tags to exclude"},{"name":"rate_limit","type":"number","default":150,"description":"Maximum requests per second"},{"name":"concurrency","type":"number","default":25,"description":"Number of concurrent templates"}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 06:25:28.748', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"NUCLEI_TEMPLATE_CUSTOM","risk_level":"LOW","tools_used":["nuclei"],"name":"Nuclei Template Scanner","description":"Performs fast and customizable vulnerability scanning using nuclei templates","category":"APPLICATION","parameters":[{"name":"severity","type":"select","options":["info","low","medium","high","critical","all"],"default":"all","description":"Minimum severity level to report"},{"name":"tags","type":"string","default":"","description":"Template tags to include (e.g., cve,rce,lfi)"},{"name":"exclude_tags","type":"string","default":"dos","description":"Template tags to exclude"},{"name":"rate_limit","type":"number","default":150,"description":"Maximum requests per second"},{"name":"concurrency","type":"number","default":25,"description":"Number of concurrent templates"}],"test_type":"vulnerability"}}', '8ddf198e19e567cc39f228feafbbad370f81392cc2e3b4188cb26fcbe62cfda1', 1, 'nuclei_template_scan.py', '2026-01-07 06:25:28.657', '2026-01-07 06:25:28.746507', NULL);
INSERT INTO public.custom_script VALUES (1, '"""Test custom script"""

SCRIPT_INFO = {
    "name": "Test Scanner",
    "tool_name": "TEST_SCANNER",
    "category": "VULNERABILITY",
    "test_type": "Custom Test",
    "description": "A test custom scanner script",
    "tool_type": "SCRIPT",
    "tools_used": [],
    "parameters": [
        {"name": "verbose", "type": "boolean", "default": False, "description": "Enable verbose output"}
    ],
    "risk_level": "LOW"
}

def execute(target, parameters, logger):
    """Execute the test scan"""
    logger.info(f"Running test scan on {target}")
    return {
        "exitCode": 0,
        "output": f"Test scan completed for {target}",
        "findings": [],
        "summary": {"status": "completed", "target": target}
    }
', 'Test Scanner', 'TEST_SCANNER', 'CUSTOM', 'Custom Test', 'A test custom scanner script', 'SCRIPT', '[]', '[{"name":"verbose","type":"boolean","default":false,"description":"Enable verbose output"}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 06:50:56.194', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":["Unknown category: VULNERABILITY. Will use CUSTOM.","RETURN_FORMAT: Script may not return the expected result format. execute() should return a dict with: findings, summary, raw_output, console_output, command_executed, exit_code, error_message. Consider using create_result() helper or ensure your return dict includes these keys."],"extractedMetadata":{"tool_name":"TEST_SCANNER","risk_level":"LOW","tool_type":"SCRIPT","tools_used":[],"name":"Test Scanner","description":"A test custom scanner script","category":"VULNERABILITY","parameters":[{"name":"verbose","type":"boolean","default":false,"description":"Enable verbose output"}],"test_type":"Custom Test"}}', '6b3a05f5335ff036c89e8180c7d58700537aa71be2b835421a6067ead320afb6', 2, 'test_script.py', '2026-01-07 02:22:39.184', '2026-01-07 06:50:56.193565', NULL);
INSERT INTO public.custom_script VALUES (8, '#!/usr/bin/env python3
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
', 'Trivy Kubernetes Scanner', 'TRIVY_K8S_MULTICONTEXT', 'KUBERNETES', 'vulnerability', 'Scans Kubernetes clusters across multiple contexts using Trivy. Detects vulnerabilities, misconfigurations, and exposed secrets in workloads.', 'script', '["trivy","kubectl"]', '[{"name":"include_namespaces","label":"Include Namespaces","type":"text","hint":"Comma-separated namespaces to include (empty = all)","default":"","required":false},{"name":"exclude_namespaces","label":"Exclude Namespaces","type":"text","hint":"Namespaces to exclude from scan (comma-separated)","default":"kube-public,kube-system,kube-node-lease","required":false},{"name":"report_type","label":"Report Type","type":"select","options":["summary","all"],"default":"summary","required":false},{"name":"parallel","label":"Parallel Scans","type":"number","hint":"Number of concurrent namespace scans","default":2,"required":false},{"name":"cluster_scan","label":"Cluster-wide Scan","type":"boolean","hint":"Also run a cluster-wide scan","default":false,"required":false}]', 'LOW', 'APPROVED', 1, 'admin', 1, 'admin', '2026-01-07 07:40:07.436', NULL, '{"valid":true,"syntaxValid":true,"hasScriptInfo":true,"hasExecuteFunction":true,"errors":[],"warnings":[],"extractedMetadata":{"tool_name":"trivy_k8s_multicontext","risk_level":"LOW","tool_type":"script","tools_used":["trivy","kubectl"],"name":"Trivy Kubernetes Scanner","description":"Scans Kubernetes clusters across multiple contexts using Trivy. Detects vulnerabilities, misconfigurations, and exposed secrets in workloads.","category":"KUBERNETES","parameters":[{"name":"include_namespaces","label":"Include Namespaces","type":"text","hint":"Comma-separated namespaces to include (empty = all)","default":"","required":false},{"name":"exclude_namespaces","label":"Exclude Namespaces","type":"text","hint":"Namespaces to exclude from scan (comma-separated)","default":"kube-public,kube-system,kube-node-lease","required":false},{"name":"report_type","label":"Report Type","type":"select","options":["summary","all"],"default":"summary","required":false},{"name":"parallel","label":"Parallel Scans","type":"number","hint":"Number of concurrent namespace scans","default":2,"required":false},{"name":"cluster_scan","label":"Cluster-wide Scan","type":"boolean","hint":"Also run a cluster-wide scan","default":false,"required":false}],"test_type":"vulnerability"}}', '9d647c22fa9da9ba7fb91afaf55a9472c6c0590689d2f2b84ddc480fa2653a14', 1, 'trivy_k8s_custom.py', '2026-01-07 07:39:46.294', '2026-01-07 07:40:07.434376', NULL);


--
-- Data for Name: environment_targets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.environment_targets VALUES (1, 1, 'petstore-api', 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', 'https://petstore.swagger.io', '{"tags": ["sample", "demo"], "description": "Sample Petstore API v2 for testing"}', true, '2026-01-09 18:28:31.597821', '2026-01-11 02:44:59.466629', '{}', 'petstore.swagger.io', 443, 'https', '/v2/swagger.json', 'REST_SERVICE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '{}');
INSERT INTO public.environment_targets VALUES (2, 1, 'httpbin', 'https://httpbin.org', NULL, NULL, '{"tags": ["testing", "http"], "description": "HTTP testing service"}', true, '2026-01-09 18:28:31.603661', '2026-01-09 18:28:31.603661', '{}', 'httpbin.org', 443, 'https', NULL, 'REST_SERVICE', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, '{}');
INSERT INTO public.environment_targets VALUES (3, 1, 'Acunetix Test PHP', 'http://testphp.vulnweb.com', NULL, NULL, '{"description": "Acunetix vulnerable web app for SQLMap testing", "testEndpoint": "/page.php?id=1"}', true, '2026-01-17 22:02:35.453711', '2026-01-17 22:02:35.453716', NULL, 'testphp.vulnweb.com', 80, 'http', NULL, 'WEB_APP', NULL, NULL, 'http://testphp.vulnweb.com', NULL, NULL, NULL, NULL, 0, NULL, NULL, '{}');
INSERT INTO public.environment_targets VALUES (4, 1, 'testhtml5.vulnweb.com', '', '', '', '{}', true, '2026-01-22 19:58:42.395054', '2026-01-22 19:58:42.395056', '{}', '', NULL, 'https', '', 'WEB_APP', '', '', 'http://testhtml5.vulnweb.com', '', '', '', '', 0, NULL, NULL, '{}');
INSERT INTO public.environment_targets VALUES (6, 1, 'Lingo', NULL, NULL, NULL, NULL, true, '2026-01-29 02:18:41.223858', '2026-01-29 02:18:41.223861', NULL, NULL, NULL, 'https', NULL, 'WEB_APP', NULL, NULL, 'https://lingo.com', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL);
INSERT INTO public.environment_targets VALUES (5, 1, 'SauceDemo', NULL, NULL, NULL, '{"tags": ["webdriver", "selenium", "demo", "e-commerce"], "features": ["login", "shopping cart", "checkout", "inventory"], "description": "Sauce Labs demo e-commerce site for WebDriver testing"}', true, '2026-01-27 03:37:18.519145', '2026-01-30 21:51:22.756641', '{"authType": "form", "loginUrl": "https://www.saucedemo.com", "password": "ENC:xuJ342EqSVs/7uHk9acSw16SRt+0cEyVgc8HuReOBCAuU5lRKK+Npg==", "username": "standard_user", "submitButton": "#login-button", "passwordField": "ENC:yjqBqCOL/zIIaUjDwM3eVwg6MJcww71wGfWyFo3BkmudL/2fUg==", "usernameField": "#user-name", "alternateUsers": {"problem_user": "secret_sauce", "locked_out_user": "secret_sauce", "performance_glitch_user": "secret_sauce"}}', 'www.saucedemo.com', 443, 'https', NULL, 'WEB_APP', NULL, NULL, 'https://www.saucedemo.com', NULL, NULL, NULL, NULL, 0, NULL, NULL, '{"urlDataAttributes": ["data-href", "data-link"], "urlExtractionPatterns": [{"idPattern": "item_(\\d+)_title_link", "urlTemplate": "/inventory-item.html?id=$1"}]}');
INSERT INTO public.environment_targets VALUES (7, 2, 'SauceDemo', NULL, NULL, NULL, NULL, true, '2026-01-31 03:55:41.091196', '2026-01-31 03:55:41.091197', NULL, 'www.saucedemo.com', 443, 'https', NULL, 'WEB_APP', NULL, NULL, 'https://www.saucedemo.com', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL);
INSERT INTO public.environment_targets VALUES (8, 2, 'Walmart', NULL, NULL, NULL, NULL, true, '2026-01-31 05:25:12.360272', '2026-01-31 05:25:12.360276', NULL, 'www.walmart.com', 443, 'https', NULL, 'WEB_APP', NULL, NULL, 'https://www.walmart.com', NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL);


--
-- Data for Name: environments; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.environments VALUES (3, 'production', 'Production environment', true, '2026-01-09 18:28:31.591772', '2026-01-09 18:28:31.591772', 'system', NULL, '{}', NULL, 0);
INSERT INTO public.environments VALUES (1, 'development', 'Development environment for testing', true, '2026-01-09 18:28:31.591772', '2026-01-14 08:12:10.461581', 'system', NULL, '{}', 1, 0);
INSERT INTO public.environments VALUES (2, 'staging', 'Staging environment for pre-production testing', true, '2026-01-09 18:28:31.591772', '2026-01-14 08:12:43.225159', 'system', NULL, '{}', 1, 0);


--
-- Data for Name: header_injection_presets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.header_injection_presets VALUES (1, 'Host Header Attack', 'Tests for Host header injection vulnerabilities. Can lead to cache poisoning, password reset poisoning, and SSRF.', '[{"payloads": ["evil.com", "localhost", "127.0.0.1", "internal.local"], "headerName": "Host", "description": "Host header override"}, {"payloads": ["evil.com", "attacker.com"], "headerName": "X-Forwarded-Host", "description": "Forwarded host spoofing"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets VALUES (2, 'X-Forwarded Headers', 'Tests X-Forwarded-* headers for IP spoofing and trust bypass vulnerabilities.', '[{"payloads": ["127.0.0.1", "10.0.0.1", "192.168.1.1", "::1"], "headerName": "X-Forwarded-For", "description": "IP address spoofing"}, {"payloads": ["https", "http"], "headerName": "X-Forwarded-Proto", "description": "Protocol spoofing"}, {"payloads": ["127.0.0.1", "10.0.0.1"], "headerName": "X-Real-IP", "description": "Real IP override"}, {"payloads": ["127.0.0.1", "192.168.1.1"], "headerName": "X-Client-IP", "description": "Client IP spoofing"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets VALUES (3, 'CRLF Injection', 'Tests for Carriage Return Line Feed injection in headers. Can lead to response splitting and header injection.', '[{"payloads": ["value\\r\\nX-Injected: true", "value\\r\\n\\r\\n<script>alert(1)</script>", "value%0d%0aX-Injected:%20true"], "headerName": "X-Custom-Header", "description": "CRLF injection attempts"}, {"payloads": ["Mozilla/5.0\\r\\nX-Injected: true"], "headerName": "User-Agent", "description": "User-Agent CRLF"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets VALUES (4, 'Cache Poisoning', 'Tests headers that may affect caching behavior and lead to cache poisoning attacks.', '[{"payloads": ["evil.com", "attacker.com"], "headerName": "X-Forwarded-Host", "description": "Cache key poisoning via host"}, {"payloads": ["nothttps", "http"], "headerName": "X-Forwarded-Scheme", "description": "Scheme-based cache poisoning"}, {"payloads": ["/admin", "/internal/config"], "headerName": "X-Original-URL", "description": "URL override for cache"}, {"payloads": ["/admin", "/../admin"], "headerName": "X-Rewrite-URL", "description": "URL rewrite exploitation"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets VALUES (5, 'Authentication Bypass Headers', 'Tests headers commonly used for authentication bypass in misconfigured proxies/load balancers.', '[{"payloads": ["/admin", "/api/admin", "/internal"], "headerName": "X-Original-URL", "description": "Original URL override"}, {"payloads": ["/admin", "/management"], "headerName": "X-Rewrite-URL", "description": "URL rewrite bypass"}, {"payloads": ["127.0.0.1"], "headerName": "X-Custom-IP-Authorization", "description": "Custom auth header"}, {"payloads": ["127.0.0.1", "::1"], "headerName": "X-Forwarded-For", "description": "Trusted IP bypass"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);
INSERT INTO public.header_injection_presets VALUES (6, 'Content Type Manipulation', 'Tests Content-Type header manipulation for parser differential attacks.', '[{"payloads": ["application/json", "application/xml", "text/xml", "application/x-www-form-urlencoded"], "headerName": "Content-Type", "description": "Content type switching"}, {"payloads": ["application/json", "text/html", "*/*"], "headerName": "Accept", "description": "Accept header manipulation"}]', true, true, '2026-01-10 20:59:03.141185', '2026-01-10 20:59:03.141185', 'system', 0);


--
-- Data for Name: license; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.license VALUES (1, 'EVALUATION', '2026-01-02 06:41:13.307794', '2027-01-02 06:41:13.307794', 'ACTIVE', 365, '1.0.0', '2026-01-02 06:41:13.307794', '2026-01-02 06:41:13.307794', NULL, 0);


--
-- Data for Name: performance_scenarios; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.performance_scenarios VALUES (1, 'Test Performance Scenario', 'Quick load test for testing', NULL, NULL, NULL, 'https://httpbin.org', NULL, '{"config": {"http": {"timeout": 30}, "phases": [{"name": "Load Test", "duration": 60, "arrivalRate": 10}], "target": "https://httpbin.org"}, "scenarios": [{"flow": [{"get": {"url": "/"}}], "name": "Performance Test"}]}', 'LOAD_TEST', NULL, NULL, NULL, true, '2026-01-17 05:10:11.497407', '2026-01-17 05:10:11.497412', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (2, 'New Performance Test', '', NULL, NULL, NULL, 'https://pravda.ru', NULL, '{"config": {"http": {"timeout": 30}, "phases": [{"name": "Load Test", "duration": 60, "arrivalRate": 10}], "target": "https://pravda.ru", "plugins": {"ensure": {"thresholds": [{"http.response_time.p95": 500}, {"http.response_time.p99": 1000}, {"http.error_rate": 0.01}]}}}, "scenarios": [{"flow": [{"get": {"url": "/"}}], "name": "Performance Test"}]}', 'LOAD_TEST', 500, 1000, 1.00, true, '2026-01-17 05:18:47.216397', '2026-01-17 05:18:47.216402', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (3, 'Python Scanner Test 2', NULL, NULL, NULL, NULL, 'https://httpbin.org', NULL, '{"flow": [{"get": {"url": "/get"}}, {"post": {"url": "/post", "json": {"test": "data"}}}], "mode": "scenario", "ensure": {"thresholds": [{"http.response_time.p95": 500}, {"http.response_time.p99": 1000}, {"http.error_rate": 0.01}]}, "phases": [{"name": "Load Test", "duration": 30, "arrivalRate": 5}], "timeout": 30, "maxErrorRate": 1.0, "scenarioName": "Python Scanner Test 2", "p95_threshold": 500, "p99_threshold": 1000}', 'LOAD_TEST', 500, 1000, 1.00, true, '2026-01-17 05:31:20.603385', '2026-01-17 05:31:20.603388', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (4, 'Test1 - Load Test', 'Generated from API Scenario: Test1', 1, 1, 1, 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', '{"flow": [{"post": {"url": "/pet", "json": {"id": 0, "name": "doggie", "tags": [{"id": 0, "name": "string"}], "status": "available", "category": {"id": 0, "name": "string"}, "photoUrls": ["string"]}, "headers": {"Content-Type": "application/json"}}}, {"think": 1}, {"get": {"url": "/pet/{petId}"}}, {"think": 1}], "mode": "scenario", "ensure": {"thresholds": [{"http.response_time.p95": 1000}, {"http.response_time.p99": 2000}, {"http.error_rate": 0.05}]}, "phases": [{"name": "Load Test", "duration": 60, "arrivalRate": 29}], "timeout": 30, "maxErrorRate": 5.0, "scenarioName": "Test1 - Load Test", "p95_threshold": 1000, "p99_threshold": 2000}', 'LOAD_TEST', 1000, 2000, 5.00, true, '2026-01-21 07:55:21.244415', '2026-01-21 07:55:21.244417', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (6, 'Data Provider Test', 'Test with CSV data and response validation', NULL, NULL, NULL, 'https://httpbin.org', NULL, '{"flow": [{"post": {"url": "/post", "json": {"message": "{{ message }}", "username": "{{ username }}"}}}], "mode": "scenario", "phases": [{"name": "Quick Test", "duration": 10, "arrivalRate": 2}], "payload": {"data": [{"message": "Hello from user1", "username": "user1"}, {"message": "Hello from user2", "username": "user2"}, {"message": "Hello from user3", "username": "user3"}], "order": "sequence", "fields": ["username", "message"]}, "plugins": {"expect": {"outputFormat": "pretty", "expectDefault200": true}}}', 'LOAD_TEST', NULL, NULL, NULL, true, '2026-01-22 05:26:30.54298', '2026-01-22 05:26:30.542982', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (7, 'Performance Test - petstore.swagger.io', '', 1, NULL, NULL, 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', '{"flow": [{"post": {"url": "/pet"}}], "mode": "scenario", "phases": [{"name": "Load Test", "duration": 60, "arrivalRate": 10}], "timeout": 30, "scenarioName": "Performance Test - petstore.swagger.io"}', 'LOAD_TEST', NULL, NULL, NULL, true, '2026-01-22 07:32:51.893864', '2026-01-22 07:32:51.893868', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (8, 'Test1 - Load Test (1)', 'Generated from API Scenario: Test1', 1, 1, 1, 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', '{"flow": [{"post": {"url": "/pet", "json": {"id": 0, "name": "doggie", "tags": [{"id": 0, "name": "string"}], "status": "available", "category": {"id": 0, "name": "string"}, "photoUrls": ["string"]}, "capture": [{"as": "petId", "json": "$.id"}], "headers": {"Content-Type": "application/json"}}}, {"think": 1}, {"get": {"url": "/pet/{petId}"}}, {"think": 1}], "mode": "scenario", "ensure": {"thresholds": [{"http.response_time.p95": 500}, {"http.response_time.p99": 1000}, {"http.error_rate": 0.01}]}, "phases": [{"name": "Load Test", "duration": 30, "arrivalRate": 10}], "timeout": 30, "maxErrorRate": 1.0, "scenarioName": "Test1 - Load Test (1)", "p95_threshold": 500, "p99_threshold": 1000}', 'LOAD_TEST', 500, 1000, 1.00, true, '2026-01-22 16:08:01.158197', '2026-01-22 16:08:01.1866', 'admin', 'admin', 0, 13);
INSERT INTO public.performance_scenarios VALUES (9, 'Performance Test - petstore.swagger.io Jan 29', '', 1, NULL, NULL, 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', '{"flow": [{"post": {"url": "/pet"}}, {"put": {"url": "/pet"}}, {"get": {"url": "/pet/{petId}"}}, {"delete": {"url": "/pet/{petId}"}}], "mode": "scenario", "ensure": {"thresholds": [{"http.response_time.p95": 500}, {"http.response_time.p99": 1000}, {"http.error_rate": 0.01}]}, "phases": [{"name": "Warm up", "rampTo": 15, "duration": 60, "arrivalRate": 5}, {"name": "Ramp to peak", "rampTo": 30, "duration": 60, "arrivalRate": 15}], "timeout": 30, "maxErrorRate": 1, "scenarioName": "Performance Test - petstore.swagger.io Jan 29", "p95_threshold": 500, "p99_threshold": 1000}', 'LOAD_TEST', 500, 1000, 1.00, true, '2026-01-30 03:30:10.618913', '2026-01-30 03:30:10.618914', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (10, 'Performance Test - pet store 1.2', 'testing 2', 1, NULL, NULL, 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', '{"flow": [{"post": {"url": "/pet"}}, {"put": {"url": "/pet"}}, {"get": {"url": "/pet/{petId}"}}], "mode": "scenario", "ensure": {"thresholds": [{"http.response_time.p95": 500}, {"http.response_time.p99": 1000}, {"http.error_rate": 0.01}]}, "phases": [{"name": "Load Test", "duration": 60, "arrivalRate": 10}], "timeout": 30, "maxErrorRate": 1, "scenarioName": "Performance Test - pet store 1.2", "p95_threshold": 500, "p99_threshold": 1000}', 'LOAD_TEST', 500, 1000, 1.00, true, '2026-01-30 07:05:08.081868', '2026-01-30 07:05:08.08187', 'admin', 'admin', 0, NULL);
INSERT INTO public.performance_scenarios VALUES (13, 'Test1 - Load Test (2)', 'Generated from API Scenario: Test1', NULL, NULL, NULL, 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', '{"flow": [{"post": {"url": "/pet", "json": {"id": "{{ $randomNumber(1, 1000) }}", "name": "{{ $randomString(10) }}", "tags": [], "status": "{{ $randomString(8) }}", "category": {}, "photoUrls": []}, "capture": [{"as": "petId", "json": "$.id"}], "headers": {"Content-Type": "application/json"}}}, {"get": {"url": "/pet/{{petId}}"}}], "mode": "scenario", "phases": [{"name": "Load Test", "duration": 60, "arrivalRate": 10}]}', 'LOAD_TEST', NULL, NULL, NULL, true, '2026-01-30 08:22:03.75924', '2026-01-30 08:24:14.258313', 'admin', 'admin', 0, 13);
INSERT INTO public.performance_scenarios VALUES (12, 'Performance Test - petstore.swagger.io 2.2 fixed', '', NULL, NULL, NULL, 'https://petstore.swagger.io/v2', 'https://petstore.swagger.io/v2/swagger.json', '{"flow": [{"post": {"url": "/pet", "json": {"id": "{{ $randomNumber(1, 1000) }}", "name": "{{ $randomString(10) }}", "tags": [], "status": "{{ $randomString(8) }}", "category": {}, "photoUrls": []}, "headers": {"Content-Type": "application/json"}}}], "mode": "scenario", "phases": [{"name": "Load Test", "duration": 60, "arrivalRate": 10}], "maxErrorRate": 1, "p95_threshold": 500, "p99_threshold": 1000}', 'LOAD_TEST', 500, 1000, 1.00, true, '2026-01-30 07:25:52.513006', '2026-01-30 08:29:22.681073', 'admin', 'admin', 0, NULL);


--
-- Data for Name: project_applications; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.project_applications VALUES (1, 1, 'user-service', 'User authentication service', 'GITHUB', 'https://github.com/example/user-service', 'main', true, '2026-01-16 06:44:36.366256', '2026-01-16 06:44:36.366261', 'admin', 'admin', 0);
INSERT INTO public.project_applications VALUES (2, 1, 'Php website for sqlmap testing', 'Php website for sqlmap testing', 'GITHUB', '', 'main', true, '2026-01-17 21:21:09.654905', '2026-01-17 21:21:09.654907', 'admin', 'admin', 0);


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.projects VALUES (1, 'Default Project', 'Default project for existing environments', NULL, true, '2026-01-14 07:23:47.260807', '2026-01-14 07:23:47.260807', 'system', NULL, 0);


--
-- Data for Name: scan_comparison; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: scan_group; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.scan_group VALUES (1, '2025-12-23 23:47:05.421', '2025-12-23 23:47:05.421', 'Test Group - Dev Network', 'Test scan group for development network', 'dev', '["scanme.nmap.org", "localhost"]', 'SEQUENTIAL', true, false, 0);


--
-- Data for Name: scan_group_templates; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.scan_group_templates VALUES (1, 1, 1, 0, 0);
INSERT INTO public.scan_group_templates VALUES (2, 1, 2, 1, 0);


--
-- Data for Name: scan_preset; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.scan_preset VALUES (1, 'Quick Web Scan', 'Fast 60-second Nikto scan for quick assessments and development testing', 21, '${TARGET}', '{"maxtime":"-maxtime 60s","tuning":"-Tuning 1","plugins":"","port":"","ssl":""}', 'quick,web,dev', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 08:31:36.889076', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset VALUES (3, 'Comprehensive Assessment', 'Thorough 5-minute security scan with extensive tuning for deep analysis', 21, '${TARGET}', '{"maxtime":"-maxtime 300s","tuning":"-Tuning 123456789","plugins":"","port":"","ssl":""}', 'comprehensive,thorough,monthly', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 08:31:36.889076', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset VALUES (4, 'SSL/TLS Security Check', 'Focus on SSL/TLS configuration and HTTPS security', 21, '${TARGET}', '{"maxtime":"-maxtime 90s","tuning":"-Tuning 23","plugins":"","port":"","ssl":"-ssl"}', 'ssl,tls,https', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 08:31:36.889076', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset VALUES (5, 'My Custom Scan', 'Testing preset creation', 21, '${TARGET}', '{"maxtime":"-maxtime 30s","tuning":"-Tuning 1"}', 'test,custom', 'test', 'presettest', '2025-12-26 22:30:41.312', '2025-12-26 22:30:41.312', NULL, false, true, 0, 0);
INSERT INTO public.scan_preset VALUES (2, 'Standard Security Audit', 'Comprehensive Nikto scan with tuning 1234 for regular security assessments', 21, '${TARGET}', '{"maxtime":"-maxtime 120s","tuning":"-Tuning 1234","plugins":"","port":"","ssl":""}', 'standard,audit,production', 'security', 'system', '2025-12-26 08:31:36.889076', '2025-12-26 23:00:22.073692', '2025-12-26 23:00:22.11', true, false, 1, 0);
INSERT INTO public.scan_preset VALUES (6, 'my preset 1', 'for dev env', 21, 'http://testphp.vulnweb.com', '{"ssl": "", "port": "", "tuning": "", "maxtime": "-maxtime 100s", "plugins": ""}', 'dev', 'security', 'testuser', '2025-12-26 22:48:36.961', '2025-12-27 06:40:34.429113', '2025-12-27 06:40:34.458', false, false, 2, 0);
INSERT INTO public.scan_preset VALUES (7, 'ZAP Baseline Scan', 'Quick passive ZAP scan (5 min spider + passive scan). Fast and non-intrusive.', 22, '${TARGET}', '{"scan_type":"","max_duration":"5"}', '{baseline,ci-cd,passive,quick}', 'security', 'system', '2025-12-26 23:37:18.941482', '2025-12-27 06:53:37.124149', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset VALUES (8, 'ZAP Active Scan', 'Comprehensive ZAP scan with spider, active scan, and passive scan (30 min). Thorough but slow.', 22, '${TARGET}', '{"scan_type":"full","max_duration":"30"}', '{active,comprehensive,spider,thorough}', 'security', 'system', '2025-12-26 23:37:18.95124', '2025-12-27 06:53:37.132018', '2025-12-27 06:37:49.345', true, false, 1, 0);
INSERT INTO public.scan_preset VALUES (9, 'ZAP API Security Scan', 'ZAP API security scan (passive only, 15 min). Optimized for REST APIs.', 22, '${TARGET}', '{"scan_type":"api","max_duration":"15"}', '{api,rest,security,info-level}', 'api-security', 'system', '2025-12-26 23:37:18.956703', '2025-12-27 06:53:37.133634', NULL, true, false, 0, 0);
INSERT INTO public.scan_preset VALUES (10, 'ZAP Quick Scan', 'Ultra-fast ZAP baseline scan (3 min spider + passive). Good for quick checks.', 22, '${TARGET}', '{"scan_type":"","max_duration":"3"}', '{quick,fast,validation}', 'security', 'system', '2025-12-26 23:37:18.958363', '2026-01-21 09:26:44.721086', '2026-01-21 09:26:44.795', true, false, 1, 1);


--
-- Data for Name: scan_schedule; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: scan_template; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.scan_template VALUES (5, 'WEB', 'test1', 'test1', 'test', 'test 1', 'test 123', 300, 'JSON', '2025-12-19 18:30:35.766', '2025-12-19 18:30:35.766', NULL, 'LOW', 0);
INSERT INTO public.scan_template VALUES (6, 'INFRASTRUCTURE', 'PORT_SCAN', 'TESTOOL', 'Test Template 1766187724 UPDATED', 'Updated description for testing', 'testool -target ${target} -output ${output_file}', 900, 'JSON', '2025-12-19 23:42:04.983', '2025-12-19 23:42:05.113', NULL, 'LOW', 0);
INSERT INTO public.scan_template VALUES (3, 'INFRASTRUCTURE', 'PORT_SCAN', 'NMAP', 'Nmap Aggressive Scan', 'Aggressive scan with OS detection and scripts', 'nmap -sT -A -T4 ${target} -p ${ports} -oX ${output_file}', 5400, 'XML', '2025-12-19 08:05:16.3901', '2025-12-19 08:05:16.3901', '{"parameters": [{"hint": "Format: Port ranges or comma-separated ports. Examples: ''80'' (single port), ''1-1000'' (range), ''80,443,8080'' (multiple ports), ''1-65535'' (all ports). Default: 1-1000", "name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Specify which ports to scan", "placeholder": "1-1000"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (33, 'INFRASTRUCTURE', 'VULNERABILITY_SCAN', 'TRIVY', 'Trivy Container Image Scan', 'Scan container images for OS packages, CVEs, misconfigurations, and secrets. Risk Level: LOW - Safe scanning.', 'trivy image --format json --output ${output_file} ${target}', 1800, 'JSON', '2025-12-28 04:14:56.856305', '2025-12-28 04:14:56.856305', '{"parameters": []}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (34, 'INFRASTRUCTURE', 'VULNERABILITY_SCAN', 'TRIVY', 'Trivy Filesystem Scan', 'Scan local filesystem for vulnerabilities in dependencies and configurations. Risk Level: LOW.', 'trivy fs --format json --output ${output_file} ${target}', 1200, 'JSON', '2025-12-28 04:14:56.856305', '2025-12-28 04:14:56.856305', '{"parameters": []}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (23, 'INFRASTRUCTURE', 'VULNERABILITY_SCAN', 'NMAP', 'NMAP Vulnerability Scan', 'Safe vulnerability detection using NSE vuln category. Checks for known CVEs and security issues. Risk Level: LOW - Safe for production.', 'nmap -sV --script vuln -oX ${output_file} ${target}', 3600, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "vuln", "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (25, 'INFRASTRUCTURE', 'SSL_TLS_AUDIT', 'NMAP', 'NMAP SSL/TLS Security Audit', 'Comprehensive SSL/TLS security analysis including cipher suites, certificates, and known SSL vulnerabilities. Risk Level: LOW - Safe.', 'nmap -sV --script ssl-enum-ciphers,ssl-cert,ssl-known-key -p 443 -oX ${output_file} ${target}', 1800, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "ssl-enum-ciphers,ssl-cert,ssl-known-key", "required": false}, {"hint": "Ports to scan", "name": "ports", "type": "text", "label": "Ports", "default": "443", "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (26, 'INFRASTRUCTURE', 'MALWARE_DETECTION', 'NMAP', 'NMAP Malware Detection', 'Check for malware infections, backdoors, and compromised services. Risk Level: LOW - Safe for production.', 'nmap --script malware -oX ${output_file} ${target}', 1800, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "malware", "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (28, 'INFRASTRUCTURE', 'INTRUSIVE_SCAN', 'NMAP', 'NMAP Intrusive Scan', '⚠️⚠️ EXTREME WARNING: Aggressive testing including vulnerability detection, exploitation attempts, and intrusive probes. Risk Level: VERY HIGH - May crash services, consume resources, trigger alerts. AUTHORIZED PENTESTING ONLY.', 'nmap -sV --script "vuln,exploit,intrusive" -oX ${output_file} ${target}', 7200, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "vuln,exploit,intrusive", "required": false}]}', 'CRITICAL', 0);
INSERT INTO public.scan_template VALUES (1, 'INFRASTRUCTURE', 'PORT_SCAN', 'NMAP', 'Nmap Quick Scan', 'Fast TCP SYN scan of top 1000 ports', 'nmap -sT -T4 ${target} --top-ports 1000 -oX ${output_file}', 3600, 'XML', '2025-12-19 08:05:16.3901', '2025-12-19 08:05:16.3901', '{"parameters": [{"hint": "Leave empty for top 1000 ports (default). Use 1-65535 for all ports.", "name": "ports", "type": "text", "label": "Port Range", "default": "", "required": false, "description": "Custom port range to scan", "placeholder": "1-1000, 22,80,443, or 1-65535"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping Check (-Pn)", "default": false, "required": false, "description": "Treat host as online without ping. Required for firewalled hosts that block ICMP.", "checkboxValue": "true"}, {"hint": "0=Paranoid (IDS evasion)  1=Sneaky  2=Polite  3=Normal  4=Aggressive (default)  5=Insane (may miss ports)", "name": "timing", "type": "text", "label": "Timing Template (0-5)", "default": "4", "required": false, "description": "Scan speed vs accuracy tradeoff"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (35, 'INFRASTRUCTURE', 'CONFIGURATION_SCAN', 'TRIVY', 'Trivy Configuration Scan', 'Scan IaC files (Dockerfile, K8s, Terraform) for security misconfigurations. Risk Level: LOW.', 'trivy config --format json --output ${output_file} ${target}', 600, 'JSON', '2025-12-28 04:14:56.856305', '2025-12-28 04:14:56.856305', '{"parameters": []}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (52, 'PERFORMANCE', 'STRESS_TEST', 'ARTILLERY', 'Artillery Stress Test', 'Stress test - 50 RPS for 60 seconds', 'artillery quick ${target} -c 50 -n 100 -o /tmp/report.json', 300, 'JSON', '2026-01-04 19:31:00.049033', '2026-01-04 19:31:00.049033', '{"vus": 50, "requests": 100}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (50, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Quick Load Test', 'Quick performance test - 5 RPS for 10 seconds', 'artillery quick ${target} -c 5 -n 10 -o /tmp/report.json', 300, 'JSON', '2026-01-04 19:31:00.049033', '2026-01-04 19:31:00.049033', '{"vus": 5, "requests": 10}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (53, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Ramp-up Load Test', 'Progressive load test that gradually increases traffic. Starts with 5 VUs/sec, ramps to 30 VUs/sec over 2 minutes. Good for finding performance degradation points.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Warm up", "rampTo": 15, "duration": 60, "arrivalRate": 5}, {"name": "Ramp to peak", "rampTo": 30, "duration": 60, "arrivalRate": 15}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (54, 'PERFORMANCE', 'STRESS_TEST', 'ARTILLERY', 'Artillery Spike Test', 'Simulates traffic spike - stable at 10 VUs/sec, then sudden burst to 100 VUs/sec for 30 seconds. Tests system resilience under sudden load.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Baseline", "duration": 30, "arrivalRate": 10}, {"name": "Spike", "duration": 30, "arrivalRate": 100}, {"name": "Recovery", "duration": 30, "arrivalRate": 10}], "maxVusers": 200}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (56, 'PERFORMANCE', 'ENDURANCE_TEST', 'ARTILLERY', 'Artillery Soak Test', 'Long-duration sustained load test at moderate traffic (10 VUs/sec for 10 minutes). Detects memory leaks, connection pool exhaustion, and gradual degradation.', 'artillery run ${config_file} -o ${output_file}', 900, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Sustained Load", "duration": 600, "arrivalRate": 10}], "maxVusers": 50}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (58, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Custom Phase Test', 'Fully customizable load test with multiple phases. User specifies phases array with duration, arrivalRate, rampTo, and optional maxVusers.', 'artillery run ${config_file} -o ${output_file}', 600, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "phases": [{"name": "Phase 1", "duration": 30, "arrivalRate": 5}, {"name": "Phase 2", "rampTo": 20, "duration": 60, "arrivalRate": 10}, {"name": "Phase 3", "duration": 30, "arrivalRate": 20}], "p95_threshold": 1000}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (59, 'KUBERNETES', 'vulnerability', 'TRIVY_K8S_MULTICONTEXT', 'Trivy Kubernetes Scanner', 'Scans Kubernetes clusters across multiple contexts using Trivy. Detects vulnerabilities, misconfigurations, and exposed secrets in workloads.', 'SCRIPT:TRIVY_K8S_MULTICONTEXT', 3600, 'JSON', '2026-01-07 03:16:44.983', '2026-01-07 07:40:07.448', '[{"hint": "Comma-separated namespaces to include (empty = all)", "name": "include_namespaces", "type": "text", "label": "Include Namespaces", "default": "", "required": false}, {"hint": "Namespaces to exclude from scan (comma-separated)", "name": "exclude_namespaces", "type": "text", "label": "Exclude Namespaces", "default": "kube-public,kube-system,kube-node-lease", "required": false}, {"name": "report_type", "type": "select", "label": "Report Type", "default": "summary", "options": ["summary", "all"], "required": false}, {"hint": "Number of concurrent namespace scans", "name": "parallel", "type": "number", "label": "Parallel Scans", "default": 2, "required": false}, {"hint": "Also run a cluster-wide scan", "name": "cluster_scan", "type": "boolean", "label": "Cluster-wide Scan", "default": false, "required": false}]', 'LOW', 0);
INSERT INTO public.scan_template VALUES (55, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery CI/CD Performance Gate', 'Performance test for CI/CD pipelines with SLO thresholds. Fails if P95 > 500ms or error rate > 1%. Returns non-zero exit code on threshold breach.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"mode": "scenario", "duration": 60, "phaseName": "CI Performance Gate", "arrivalRate": 20, "maxErrorRate": 1, "p95_threshold": 500, "p99_threshold": 1000}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (57, 'PERFORMANCE', 'API_TEST', 'ARTILLERY', 'Artillery API POST Test', 'Load test for POST endpoints. Configurable method, headers (e.g., Authorization), and JSON body. Supports authenticated API testing.', 'artillery run ${config_file} -o ${output_file}', 300, 'JSON', '2026-01-05 01:37:48.382495', '2026-01-05 01:37:48.382495', '{"body": {"key": "value"}, "mode": "scenario", "path": "/api/endpoint", "method": "post", "headers": {"Content-Type": "application/json", "Authorization": "Bearer ${token}"}, "duration": 60, "arrivalRate": 10, "scenarioName": "API Test"}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (63, 'NETWORK', 'vulnerability', 'NMAP_VULN_CUSTOM', 'Nmap Vulnerability Scanner', 'Performs network vulnerability scanning using nmap with NSE vulnerability scripts', 'SCRIPT:NMAP_VULN_CUSTOM', 3600, 'JSON', '2026-01-07 06:23:59.936', '2026-01-07 06:23:59.936', '[{"name": "scan_type", "type": "select", "default": "standard", "options": ["quick", "standard", "deep"], "description": "Scan intensity level"}, {"name": "ports", "type": "string", "default": "1-1000", "description": "Port range to scan (e.g., 1-1000, 22,80,443)"}, {"name": "scripts", "type": "string", "default": "vuln", "description": "NSE script categories to run (e.g., vuln, default, safe)"}]', 'LOW', 0);
INSERT INTO public.scan_template VALUES (66, 'APPLICATION', 'vulnerability', 'NUCLEI_TEMPLATE_CUSTOM', 'Nuclei Template Scanner', 'Performs fast and customizable vulnerability scanning using nuclei templates', 'SCRIPT:NUCLEI_TEMPLATE_CUSTOM', 3600, 'JSON', '2026-01-07 06:25:28.748', '2026-01-07 06:25:28.748', '{"parameters": [{"name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high,medium,low", "required": false, "description": "Comma-separated severity levels", "placeholder": "critical,high,medium,low,info"}, {"name": "tags", "type": "text", "label": "Template Tags", "default": "", "required": false, "description": "Filter templates by tag", "placeholder": "cve,owasp,tech-detect"}, {"name": "exclude_tags", "type": "text", "label": "Exclude Tags", "default": "", "required": false, "description": "Exclude templates by tag", "placeholder": "dos,fuzz"}, {"name": "rate_limit", "type": "number", "label": "Rate Limit (req/sec)", "default": 150, "required": false, "description": "Maximum requests per second"}, {"name": "concurrency", "type": "number", "label": "Concurrency", "default": 25, "required": false, "description": "Number of concurrent template executions"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (65, 'APPLICATION', 'vulnerability', 'SQLMAP_INJECT_CUSTOM', 'SQLMap Injection Scanner', 'Performs automated SQL injection detection and exploitation testing using sqlmap', 'SCRIPT:SQLMAP_INJECT_CUSTOM', 3600, 'JSON', '2026-01-07 06:25:28.469', '2026-01-07 06:25:28.469', '{"parameters": [{"hint": "1=Safe 2=Moderate 3=Aggressive", "name": "risk", "type": "text", "label": "Risk Level (1-3)", "default": "1", "required": false, "description": "Risk of tests"}, {"hint": "1=Basic 2=Cookie 3=Headers 4=More 5=All", "name": "level", "type": "text", "label": "Test Level (1-5)", "default": "1", "required": false, "description": "Level of tests"}, {"name": "dbms", "type": "text", "label": "Target DBMS", "default": "", "required": false, "placeholder": "mysql, postgresql, mssql, oracle"}, {"hint": "B=Boolean E=Error U=Union S=Stacked T=Time Q=Inline", "name": "technique", "type": "text", "label": "Techniques (BEUSTQ)", "default": "", "required": false}, {"name": "threads", "type": "number", "label": "Threads", "default": 1, "required": false}, {"name": "forms", "type": "checkbox", "label": "Test Forms", "default": false, "required": false, "checkboxValue": "true"}, {"hint": "0=Disabled. Auto-discover injectable URLs.", "name": "crawl", "type": "text", "label": "Crawl Depth (0-5)", "default": "0", "required": false}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (69, 'CUSTOM', 'Custom Test', 'TEST_SCANNER', 'Test Scanner', 'A test custom scanner script', 'SCRIPT:TEST_SCANNER', 3600, 'JSON', '2026-01-07 06:50:56.197', '2026-01-07 06:50:56.197', '[{"name": "verbose", "type": "boolean", "default": false, "description": "Enable verbose output"}]', 'LOW', 0);
INSERT INTO public.scan_template VALUES (70, 'API_SECURITY', 'SQL_INJECTION', 'API_SCANNER', 'API SQL Injection Test', 'Tests API endpoints for SQL injection vulnerabilities using predefined payloads', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "GET", "options": ["GET", "POST", "PUT", "PATCH", "DELETE"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "query", "options": ["query", "body", "path", "header"]}, {"hint": "Name of parameter to inject into", "name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded", "text/plain"]}, {"hint": "Optional Bearer token or Basic auth", "name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (71, 'API_SECURITY', 'XSS', 'API_SCANNER', 'API XSS Test', 'Tests API endpoints for Cross-Site Scripting vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "POST", "options": ["GET", "POST", "PUT", "PATCH"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "body", "options": ["query", "body", "header"]}, {"name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded"]}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (72, 'API_SECURITY', 'PATH_TRAVERSAL', 'API_SCANNER', 'API Path Traversal Test', 'Tests API endpoints for path traversal/LFI vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "GET", "options": ["GET", "POST"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "query", "options": ["query", "path"]}, {"hint": "File path parameter", "name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (73, 'API_SECURITY', 'COMMAND_INJECTION', 'API_SCANNER', 'API Command Injection Test', 'Tests API endpoints for OS command injection vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "POST", "options": ["GET", "POST"]}, {"name": "inject_location", "type": "select", "label": "Injection Point", "default": "body", "options": ["query", "body"]}, {"name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded"]}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}]}', 'CRITICAL', 0);
INSERT INTO public.scan_template VALUES (74, 'API_SECURITY', 'AUTH_BYPASS', 'API_SCANNER', 'API Authentication Bypass Test', 'Tests API authentication mechanisms for bypass vulnerabilities', 'INTERNAL:API_SCANNER', 300, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "GET", "options": ["GET", "POST", "PUT", "DELETE"]}, {"hint": "Endpoint that requires auth", "name": "protected_endpoint", "type": "text", "label": "Protected Endpoint", "required": true}, {"hint": "Optional valid token to compare responses", "name": "valid_token", "type": "text", "label": "Valid Token"}]}', 'CRITICAL', 0);
INSERT INTO public.scan_template VALUES (75, 'API_SECURITY', 'FULL_SCAN', 'API_SCANNER', 'API Full Security Scan', 'Comprehensive API security test with all payload categories', 'INTERNAL:API_SCANNER', 900, 'JSON', '2026-01-08 07:29:13.115916', '2026-01-08 07:29:13.115916', '{"parameters": [{"name": "method", "type": "select", "label": "HTTP Method", "default": "POST", "options": ["GET", "POST", "PUT", "PATCH", "DELETE"]}, {"name": "param_name", "type": "text", "label": "Parameter Name", "required": true}, {"name": "content_type", "type": "select", "label": "Content Type", "default": "application/json", "options": ["application/json", "application/x-www-form-urlencoded"]}, {"name": "auth_header", "type": "text", "label": "Authorization Header"}, {"hint": "Comma-separated list", "name": "categories", "type": "text", "label": "Payload Categories", "default": "SQL_INJECTION,XSS,PATH_TRAVERSAL"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (32, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei Web Technology Detection', 'Detect web technologies, frameworks, and potential misconfigurations. Risk Level: LOW - Information gathering.', 'nuclei -u ${target} -tags tech,misconfiguration -json-export ${output_file}', 900, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated template tags", "name": "tags", "type": "text", "label": "Template Tags", "default": "tech,misconfiguration", "required": false}, {"hint": "Max requests per second", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false}, {"hint": "Parallel executions", "name": "concurrency", "type": "number", "label": "Concurrency", "default": 25, "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (76, 'RECONNAISSANCE', 'DISCOVERY', 'WEB_CRAWLER', 'Web Crawler - Full Discovery', 'Multi-mode web crawler for site mapping, locator extraction, and validation. Modes: discovery (page objects/locators for Webdriver testing), validation (accessibility/security rules), extraction (URLs/params for security tools like SQLMap). Risk Level: LOW - Read-only scanning.', 'web_crawler ${target} --mode ${mode} --depth ${max_depth} --max-urls ${max_urls}', 1800, 'JSON', '2026-01-17 22:32:16.428518', '2026-01-17 22:32:16.428518', '{"parameters": [{"hint": "full=all modes, discovery=locators for testing, validation=rule checking, extraction=URLs for security tools", "name": "mode", "type": "select", "label": "Crawl Mode", "default": "full", "options": ["full", "discovery", "validation", "extraction"], "required": false}, {"hint": "How deep to follow links from the starting URL", "name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "2", "options": ["1", "2", "3", "4", "5"], "required": false}, {"hint": "Maximum number of pages to crawl", "name": "max_urls", "type": "select", "label": "Max URLs to Crawl", "default": "100", "options": ["25", "50", "100", "200"], "required": false}, {"hint": "Comma-separated rules: missing_alt,form_security,missing_meta,broken_links (empty=all)", "name": "rules", "type": "text", "label": "Validation Rules", "default": "", "required": false}, {"hint": "Regex patterns to exclude from crawl. Example: logout|admin|/api/", "name": "exclude_patterns", "type": "text", "label": "Exclude URL Patterns", "default": "", "required": false}, {"hint": "Delay between requests to avoid overwhelming the target", "name": "rate_limit", "type": "select", "label": "Request Delay (seconds)", "default": "0.5", "options": ["0.2", "0.5", "1.0", "2.0"], "required": false}, {"hint": "Extract form information for security testing", "name": "collect_forms", "type": "checkbox", "label": "Collect Form Data", "required": false, "checkboxValue": "true"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (77, 'RECONNAISSANCE', 'DISCOVERY', 'WEB_CRAWLER', 'Web Crawler - Page Object Discovery', 'Crawl website to discover page elements and build locator maps for automated testing (Webdriver/QReasp). Extracts inputs, buttons, forms, and links with semantic naming. Results can be exported for test automation.', 'web_crawler ${target} --mode discovery --depth ${max_depth}', 900, 'JSON', '2026-01-17 22:32:16.435186', '2026-01-17 22:32:16.435186', '{"parameters": [{"hint": "How deep to crawl (1=landing pages only, 2=one click deep, 3=two clicks deep)", "name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "2", "options": ["1", "2", "3"], "required": false}, {"name": "max_urls", "type": "select", "label": "Max Pages", "default": "50", "options": ["25", "50", "100"], "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (78, 'DATABASE', 'SQL_INJECTION_PREP', 'WEB_CRAWLER', 'Web Crawler - SQL Injection Targets', 'Crawl website to discover all URLs with query parameters and POST forms suitable for SQL injection testing. Use with SQLMap for comprehensive database security testing.', 'web_crawler ${target} --mode extraction --depth ${max_depth}', 600, 'JSON', '2026-01-17 22:32:16.436289', '2026-01-17 22:32:16.436289', '{"parameters": [{"hint": "Deeper crawl finds more injection points but takes longer", "name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "3", "options": ["1", "2", "3", "4", "5"], "required": false}, {"name": "max_urls", "type": "select", "label": "Max URLs", "default": "100", "options": ["50", "100", "200"], "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (79, 'WEB', 'COMPLIANCE_CHECK', 'WEB_CRAWLER', 'Web Crawler - Security & Accessibility Audit', 'Validate website against security and accessibility rules. Checks: missing alt text, forms without CSRF protection, password field security, missing meta tags, and more.', 'web_crawler ${target} --mode validation --depth ${max_depth}', 900, 'JSON', '2026-01-17 22:32:16.437459', '2026-01-17 22:32:16.437459', '{"parameters": [{"hint": "Leave empty for all rules, or specify: missing_alt,form_security,missing_meta", "name": "rules", "type": "text", "label": "Rules to Check", "default": "", "required": false}, {"name": "max_depth", "type": "select", "label": "Max Crawl Depth", "default": "2", "options": ["1", "2", "3"], "required": false}, {"name": "max_urls", "type": "select", "label": "Max Pages", "default": "50", "options": ["25", "50", "100"], "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (36, 'NETWORK', 'discovery', 'NMAP', 'NSE Safe Discovery', 'Safe service and version discovery using default, safe, and version NSE scripts. Suitable for production environments.', 'nmap -sT -sV --script=default,safe,version -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.015144', '2026-01-02 06:19:48.015144', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (37, 'NETWORK', 'ssl_analysis', 'NMAP', 'SSL/TLS Certificate Analysis', 'Analyze SSL/TLS certificates and cipher suites. Identifies weak ciphers, expired certificates, and known vulnerabilities.', 'nmap -sT -sV --script=ssl-cert,ssl-enum-ciphers,ssl-known-key,ssl-date,ssl-heartbleed,ssl-poodle -p {{ports:443,8443,993,995,465}} -T{{timing:4}} -oX - {{target}}', 300, 'xml', '2026-01-02 06:19:48.018489', '2026-01-02 06:19:48.018489', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (4, 'DATABASE', 'SQL_INJECTION', 'SQLMAP', 'SQLMap Auto Scan', 'Automatic SQL injection detection and exploitation', 'sqlmap -u ${url} ${level} ${risk} ${threads} ${dbms} ${technique} ${dbs} ${tables} ${dump} --batch --output-dir=${output_dir}', 7200, 'JSON', '2025-12-19 08:05:16.394886', '2025-12-19 08:05:16.394886', '{"parameters": [{"hint": "Crawl site to discover ALL injectable URLs. Depth: 1=homepage only, 2=one click deep, 3+=deeper. Leave empty to test only the target URL.", "name": "crawl", "type": "select", "label": "Enable Site Crawling", "format": "--crawl={value}", "default": "", "options": ["", "1", "2", "3", "4", "5"], "required": false, "description": "Automatically discover and test all URLs with parameters"}, {"hint": "Also discover and report HTML forms (login forms, search boxes, etc). Requires crawl to be enabled.", "name": "forms", "type": "checkbox", "label": "Test Forms", "required": false, "description": "Include form discovery during crawl", "checkboxValue": "--forms"}, {"hint": "1=Basic (fastest), 2=Extended, 3=Good balance, 4=More thorough, 5=Maximum tests (slowest)", "name": "level", "type": "select", "label": "Detection Level", "format": "--level={value}", "default": "1", "options": ["1", "2", "3", "4", "5"], "required": false, "description": "Level of tests to perform (1-5)"}, {"hint": "1=Safe, 2=Medium (may cause data changes), 3=High (heavy queries). Use 1 for production.", "name": "risk", "type": "select", "label": "Risk Level", "format": "--risk={value}", "default": "1", "options": ["1", "2", "3"], "required": false, "description": "Risk of tests to perform (1-3)"}, {"hint": "Concurrent threads. Higher = faster but more load on target.", "name": "threads", "type": "select", "label": "Threads", "format": "--threads={value}", "default": "1", "options": ["1", "2", "3", "5", "10"], "required": false, "description": "Number of concurrent threads"}, {"hint": "Leave empty for auto-detection (recommended). SQLMap will fingerprint the database automatically.", "name": "dbms", "type": "select", "label": "Target DBMS", "format": "--dbms={value}", "default": "", "options": ["", "MySQL", "MariaDB", "PostgreSQL", "Microsoft SQL Server", "Oracle", "SQLite", "IBM DB2", "Firebird"], "required": false, "description": "Target database type. Only specify if you know the exact database."}, {"hint": "B=Boolean, E=Error, U=Union, S=Stacked, T=Time-based, Q=Inline. Default: BEUSTQ (all)", "name": "technique", "type": "text", "label": "Injection Techniques", "format": "--technique={value}", "default": "BEUSTQ", "required": false, "description": "SQL injection techniques to use"}, {"hint": "List all database names if injection is found", "name": "dbs", "type": "checkbox", "label": "Enumerate Databases", "required": false, "description": "Enumerate database names", "checkboxValue": "--dbs"}, {"hint": "List all table names if injection is found", "name": "tables", "type": "checkbox", "label": "Enumerate Tables", "required": false, "description": "Enumerate table names", "checkboxValue": "--tables"}, {"hint": "WARNING: Extract and save database contents. Only use on authorized test systems!", "name": "dump", "type": "checkbox", "label": "Dump Data", "required": false, "description": "Dump database table entries", "checkboxValue": "--dump"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (29, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei Full Vulnerability Scan', 'Comprehensive vulnerability scan using 9,000+ Nuclei templates. Checks for CVEs, misconfigurations, and security issues. Risk Level: LOW - Non-invasive testing.', 'nuclei -u ${target} -json-export ${output_file}', 1800, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated severity levels to include. Options: critical, high, medium, low, info. Example: critical,high (only critical and high findings)", "name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high,medium,low,info", "required": false, "description": "Filter templates by severity level"}, {"hint": "Comma-separated tags to filter templates. Examples: cve (known vulnerabilities), tech (technology detection), config (misconfigurations), xss, sqli, rce", "name": "tags", "type": "text", "label": "Template Tags", "required": false, "description": "Filter templates by tags (e.g., cve, tech, config)"}, {"hint": "Comma-separated tags to exclude. Example: dos,fuzz (skip DoS and fuzzing tests)", "name": "exclude_tags", "type": "text", "label": "Exclude Tags", "required": false, "description": "Exclude templates with these tags"}, {"hint": "Maximum requests per second. Lower values are safer but slower. Default: 150", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false, "description": "Maximum requests per second"}, {"hint": "Number of concurrent template executions. Default: 25", "name": "concurrency", "type": "number", "label": "Concurrency", "default": 25, "required": false, "description": "Number of parallel template executions"}, {"hint": "Timeout per request in seconds. Increase for slow targets. Default: 10", "name": "timeout", "type": "number", "label": "Request Timeout", "default": 10, "required": false, "description": "Timeout in seconds for each request"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (24, 'INFRASTRUCTURE', 'AUTHENTICATION_AUDIT', 'NMAP', 'NMAP Authentication Audit', 'Enumerate authentication methods and mechanisms. Tests SSH, HTTP, FTP, and other service authentication. Risk Level: LOW - Non-intrusive.', 'nmap -sV --script auth -oX ${output_file} ${target}', 1800, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "auth", "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (27, 'INFRASTRUCTURE', 'BRUTE_FORCE', 'NMAP', 'NMAP Brute Force Test', '⚠️ WARNING: Credential brute forcing across SSH, FTP, HTTP, MySQL, and other services. Risk Level: HIGH - May trigger alerts, lock accounts, and generate security events. AUTHORIZED USE ONLY.', 'nmap --script brute -oX ${output_file} ${target}', 7200, 'XML', '2025-12-28 03:36:41.842141', '2025-12-28 03:36:41.842141', '{"parameters": [{"hint": "Comma-separated NSE scripts or categories", "name": "scripts", "type": "text", "label": "NSE Scripts", "default": "brute", "required": false}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (30, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei Critical & High Severity Scan', 'Focused scan for critical and high severity vulnerabilities only. Faster execution with prioritized findings. Risk Level: LOW.', 'nuclei -u ${target} -severity critical,high -json-export ${output_file}', 900, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated severity levels", "name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high", "required": false}, {"hint": "Filter by tags. Examples: cve, rce, sqli", "name": "tags", "type": "text", "label": "Template Tags", "required": false}, {"hint": "Tags to exclude", "name": "exclude_tags", "type": "text", "label": "Exclude Tags", "required": false}, {"hint": "Max requests per second", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (31, 'WEB', 'VULNERABILITY_SCAN', 'NUCLEI', 'Nuclei CVE Detection Scan', 'Targeted scan for known CVEs using Nuclei CVE templates. Risk Level: LOW - Passive detection only.', 'nuclei -u ${target} -tags cve -json-export ${output_file}', 1200, 'JSON', '2025-12-28 04:14:56.84039', '2025-12-28 04:14:56.84039', '{"parameters": [{"hint": "Comma-separated template tags", "name": "tags", "type": "text", "label": "Template Tags", "default": "cve", "required": false}, {"hint": "Filter CVEs by severity. Example: critical,high", "name": "severity", "type": "text", "label": "Severity Filter", "default": "critical,high,medium,low,info", "required": false}, {"hint": "Max requests per second", "name": "rate_limit", "type": "number", "label": "Rate Limit", "default": 150, "required": false}, {"hint": "Timeout in seconds", "name": "timeout", "type": "number", "label": "Request Timeout", "default": 10, "required": false}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (88, 'WEB', 'UI_TEST', 'WEBDRIVER', 'WebDriver UI Test', 'Execute YAML-defined UI tests via Selenium WebDriver', 'webdriver-execute ${yaml_content}', 1800, 'JSON', '2026-01-24 07:37:25.188475', '2026-01-24 07:37:25.188475', '{"parameters": [{"name": "yamlContent", "type": "hidden"}, {"name": "pageObjects", "type": "hidden"}, {"name": "variables", "type": "hidden"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (51, 'PERFORMANCE', 'LOAD_TEST', 'ARTILLERY', 'Artillery Medium Load Test', 'Medium load test - 20 RPS for 30 seconds', 'artillery quick ${target} -c 20 -n 50 -o /tmp/report.json', 300, 'JSON', '2026-01-04 19:31:00.049033', '2026-01-04 19:31:00.049033', '{"vus": 20, "requests": 50}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (64, 'WEB', 'vulnerability', 'NIKTO_WEB_CUSTOM', 'Nikto Web Vulnerability Scanner', 'Performs comprehensive web server vulnerability scanning using nikto', 'SCRIPT:NIKTO_WEB_CUSTOM', 3600, 'JSON', '2026-01-07 06:25:10.812', '2026-01-08 07:37:28.656', '{"parameters": [{"name": "port", "type": "text", "label": "Port", "default": "", "required": false, "description": "Target port number", "placeholder": "443, 8080"}, {"name": "ssl", "type": "checkbox", "label": "Force SSL/HTTPS", "default": false, "required": false, "description": "Force SSL connection", "checkboxValue": "true"}, {"hint": "1=Files 2=Misconfig 3=Info 4=XSS 5=File Retrieval 6=DoS 7=RCE 8=SQLi 9=Auth Bypass 0=Upload a=Auth b=Software c=Remote d=WebService e=Admin x=Reverse", "name": "tuning", "type": "text", "label": "Scan Tuning", "default": "", "required": false, "description": "Plugin selection tuning"}, {"name": "maxtime", "type": "number", "label": "Max Scan Time (seconds)", "default": "", "required": false, "description": "Maximum scan duration in seconds", "placeholder": "300"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (80, 'DATABASE', 'SQL_INJECTION', 'SQLMAP', 'SQLMap Site Discovery Scan', 'Automatically crawl a website to discover ALL pages with parameters, then test each for SQL injection. Best for comprehensive security assessments. The crawler will find login forms, search pages, and any URL with query parameters.', 'sqlmap -u ${url} ${crawl} ${forms} ${level} ${risk} ${threads} ${dbms} ${technique} ${dbs} ${tables} ${dump} --batch --output-dir=${output_dir}', 14400, 'JSON', '2026-01-17 22:48:31.03188', '2026-01-17 22:48:31.03188', '{"parameters": [{"hint": "1=Safe  2=Moderate (default for deep)  3=Aggressive", "name": "risk", "type": "text", "label": "Risk Level", "default": "2", "required": false, "description": "Risk of tests (1-3)"}, {"hint": "1=Basic  2=Cookie  3=Headers (default for deep)  4=More  5=All", "name": "level", "type": "text", "label": "Test Level", "default": "3", "required": false, "description": "Level of tests (1-5)"}, {"name": "dbms", "type": "text", "label": "Target DBMS", "default": "", "required": false, "description": "Force specific database type", "placeholder": "mysql, postgresql, mssql, oracle"}, {"hint": "B=Boolean E=Error U=Union S=Stacked T=Time Q=Inline", "name": "technique", "type": "text", "label": "Injection Techniques", "default": "", "required": false, "description": "Techniques to test (BEUSTQ)"}, {"name": "threads", "type": "number", "label": "Threads", "default": 3, "required": false, "description": "Concurrent threads"}, {"name": "forms", "type": "checkbox", "label": "Test Forms", "default": true, "required": false, "description": "Test HTML forms on the page", "checkboxValue": "true"}, {"hint": "0=Disabled  1-5=Depth. Discovers URLs with parameters automatically.", "name": "crawl", "type": "text", "label": "Crawl Depth", "default": "2", "required": false, "description": "Crawl the site to discover injectable pages (0-5)"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (2, 'INFRASTRUCTURE', 'PORT_SCAN', 'NMAP', 'Nmap Full TCP Scan', 'Comprehensive TCP scan with version detection', 'nmap -sT -sV -p- ${target} -oX ${output_file}', 7200, 'XML', '2025-12-19 08:05:16.3901', '2025-12-19 08:05:16.3901', '{"parameters": [{"name": "no_ping", "type": "checkbox", "label": "Skip Ping Check (-Pn)", "default": false, "required": false, "description": "Treat host as online without ping. Required for firewalled hosts.", "checkboxValue": "true"}, {"name": "os_detection", "type": "checkbox", "label": "OS Detection (-O)", "default": false, "required": false, "description": "Attempt to identify the operating system", "checkboxValue": "true"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing Template (0-5)", "default": "4", "required": false, "description": "Scan speed"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (38, 'NETWORK', 'vulnerability', 'NMAP', 'NSE Vulnerability Scan', 'Scan for known vulnerabilities using the vuln NSE category. Checks for CVEs and common misconfigurations.', 'nmap -sT -sV --script=vuln -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 900, 'xml', '2026-01-02 06:19:48.019345', '2026-01-02 06:19:48.019345', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (39, 'NETWORK', 'vulnerability', 'NMAP', 'Common Vulnerability Check', 'Check for common vulnerabilities including Heartbleed, EternalBlue, Shellshock, and SMB vulnerabilities.', 'nmap -sT -sV --script=ssl-heartbleed,smb-vuln-ms17-010,smb-vuln-ms08-067,http-shellshock,http-vuln-cve2017-5638 -p {{ports:21-25,80,139,443,445,8080}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.020191', '2026-01-02 06:19:48.020191', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (40, 'WEB', 'enumeration', 'NMAP', 'HTTP Service Enumeration', 'Enumerate HTTP services including titles, headers, methods, robots.txt, and sitemap.', 'nmap -sT -sV --script=http-title,http-headers,http-methods,http-robots.txt,http-sitemap-generator,http-server-header -p {{ports:80,443,8080,8443}} -T{{timing:4}} -oX - {{target}}', 300, 'xml', '2026-01-02 06:19:48.020997', '2026-01-02 06:19:48.020997', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (41, 'WEB', 'vulnerability', 'NMAP', 'HTTP Vulnerability Check', 'Check for HTTP-specific vulnerabilities including Shellshock, slowloris, and common web vulns.', 'nmap -sT -sV --script=http-vuln-*,http-shellshock,http-slowloris-check,http-sql-injection -p {{ports:80,443,8080,8443}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.021766', '2026-01-02 06:19:48.021766', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (43, 'DATABASE', 'discovery', 'NMAP', 'Database Service Discovery', 'Discover and enumerate database services (MySQL, PostgreSQL, MongoDB, Redis, MSSQL).', 'nmap -sT -sV --script=mysql-info,mysql-databases,pgsql-brute,mongodb-info,redis-info,ms-sql-info -p {{ports:3306,5432,27017,6379,1433,1521}} -T{{timing:4}} -oX - {{target}}', 300, 'xml', '2026-01-02 06:19:48.023287', '2026-01-02 06:19:48.023287', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'LOW', 0);
INSERT INTO public.scan_template VALUES (44, 'NETWORK', 'authentication', 'NMAP', 'Authentication Methods Check', 'Check authentication methods and look for weak authentication configurations.', 'nmap -sT -sV --script=auth,ssh-auth-methods,ftp-anon,http-auth,smtp-open-relay -p {{ports:21-25,22,80,110,143,443,993,995}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.024178', '2026-01-02 06:19:48.024178', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (45, 'INFRASTRUCTURE', 'malware', 'NMAP', 'Malware Indicator Detection', 'Check for known malware indicators and backdoors.', 'nmap -sT -sV --script=malware -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 900, 'xml', '2026-01-02 06:19:48.024954', '2026-01-02 06:19:48.024954', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (46, 'NETWORK', 'audit', 'NMAP', 'Comprehensive Security Audit', 'Full security audit using multiple NSE categories. May trigger security alerts. Use with caution.', 'nmap -sT -sV -O --script=default,safe,vuln,auth -p {{ports:1-65535}} -T{{timing:4}} -oX - {{target}}', 3600, 'xml', '2026-01-02 06:19:48.025766', '2026-01-02 06:19:48.025766', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (47, 'NETWORK', 'brute_force', 'NMAP', 'Credential Brute Force (AUTHORIZED ONLY)', 'Brute force credential testing. ONLY use with explicit authorization. May lock accounts.', 'nmap -sT -sV --script=brute -p {{ports:21,22,23,25,80,110,143,443,993,995,3306,5432}} -T{{timing:3}} -oX - {{target}}', 1800, 'xml', '2026-01-02 06:19:48.026553', '2026-01-02 06:19:48.026553', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (48, 'NETWORK', 'intrusive', 'NMAP', 'Intrusive Security Scan', 'Intrusive scanning that may trigger IDS/IPS alerts and consume target resources.', 'nmap -sT -sV --script=intrusive -p {{ports:1-1000}} -T{{timing:4}} -oX - {{target}}', 1200, 'xml', '2026-01-02 06:19:48.027424', '2026-01-02 06:19:48.027424', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'HIGH', 0);
INSERT INTO public.scan_template VALUES (49, 'NETWORK', 'exploitation', 'NMAP', 'Exploitation Testing (PENTEST ONLY)', 'Attempt exploitation of known vulnerabilities. FOR AUTHORIZED PENETRATION TESTING ONLY. May crash services.', 'nmap -sT -sV --script=exploit -p {{ports:1-1000}} -T{{timing:3}} -oX - {{target}}', 1800, 'xml', '2026-01-02 06:19:48.028143', '2026-01-02 06:19:48.028143', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'CRITICAL', 0);
INSERT INTO public.scan_template VALUES (42, 'NETWORK', 'enumeration', 'NMAP', 'SMB Service Enumeration', 'Enumerate SMB shares, users, and check for SMB vulnerabilities including EternalBlue.', 'nmap -sT -sV --script=smb-enum-shares,smb-enum-users,smb-enum-sessions,smb-os-discovery,smb-security-mode,smb-vuln-* -p {{ports:139,445}} -T{{timing:4}} -oX - {{target}}', 600, 'xml', '2026-01-02 06:19:48.022529', '2026-01-02 06:19:48.022529', '{"parameters": [{"name": "ports", "type": "text", "label": "Port Range", "default": "1-1000", "required": false, "description": "Ports to scan", "placeholder": "1-1000, 22,80,443"}, {"hint": "0=Paranoid 1=Sneaky 2=Polite 3=Normal 4=Aggressive 5=Insane", "name": "timing", "type": "text", "label": "Timing (0-5)", "default": "4", "required": false, "description": "Scan speed"}, {"name": "no_ping", "type": "checkbox", "label": "Skip Ping (-Pn)", "default": false, "required": false, "description": "Required for firewalled hosts that block ICMP", "checkboxValue": "true"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (22, 'WEB', 'VULNERABILITY_SCAN', 'ZAP', 'OWASP ZAP Security Scan', 'OWASP ZAP web application security scanner. Parameters: target (URL to scan, e.g., http://testphp.vulnweb.com), output_file (auto-generated), scan_type (optional: leave empty OR "quick" for passive scan [fastest, default], "full" for spider+active+passive scan [thorough but slow, 10-20 min], "api" for API-only passive scan), max_duration (optional: spider timeout in minutes, default 5, examples: 3, 10, 15)', '/usr/local/bin/zap-scan-wrapper.sh ${target} ${output_file} ${scan_type} ${max_duration}', 1800, 'JSON', '2025-12-26 23:34:13.477865', '2025-12-26 23:34:13.477865', '{"parameters": [{"hint": "Quick: passive checks only. Full: includes spidering and active attack scanning.", "name": "scan_type", "type": "select", "label": "Scan Type", "default": "quick", "options": [{"label": "Quick Scan (passive, ~5 min)", "value": "quick"}, {"label": "Full Scan (spider + active + AJAX, ~15-30 min)", "value": "full"}], "required": false, "description": "ZAP scan mode - quick is faster, full is more thorough"}]}', 'MEDIUM', 0);
INSERT INTO public.scan_template VALUES (21, 'WEB', 'WEB_SECURITY', 'NIKTO', 'Nikto Web Server Scan', 'Comprehensive web server scanner that tests for over 6700 potentially dangerous files/programs, outdated versions, and server configuration issues.', 'nikto -h ${target} ${port} ${ssl} ${tuning} ${plugins} ${maxtime} -o ${output_file} -Format txt', 1800, 'TEXT', '2025-12-26 04:37:32.545786', '2025-12-26 04:37:32.545786', '{"parameters": [{"hint": "Format: <number><unit> where unit is s (seconds), m (minutes), or h (hours). Examples: 5m, 10m, 30m", "name": "maxtime", "type": "text", "label": "Max Scan Time", "format": "-maxtime {value}", "default": "10m", "required": false, "description": "Maximum scan duration. Leave empty for no limit.", "placeholder": "10m"}, {"hint": "Enter a single port number between 1-65535", "name": "port", "type": "number", "label": "Port", "format": "-port {value}", "required": false, "description": "Target port (optional, default: 80 for HTTP, 443 for HTTPS)", "placeholder": "80"}, {"hint": "Check this box if the target uses HTTPS", "name": "ssl", "type": "checkbox", "label": "Use SSL/HTTPS", "required": false, "description": "Force SSL/HTTPS mode on the specified port", "checkboxValue": "-ssl"}, {"hint": "Format: Concatenated digits (NO commas, NO spaces). Examples: ''1'' (only Interesting Files), ''123'' (Files + Config + Info), ''4'' (only XSS/Injection). Options: 1=Files, 2=Config, 3=Info, 4=XSS/Injection, 5=RFI-WebRoot, 6=DoS, 7=RFI-ServerWide, 8=Cmd Exec, 9=SQL Injection, 0=File Upload, a=Auth Bypass, b=Software ID, c=Source Inclusion, x=Reverse (all EXCEPT specified)", "name": "tuning", "type": "text", "label": "Scan Tuning", "format": "-Tuning {value}", "required": false, "description": "Select which test categories to run (see options below)", "placeholder": "123"}, {"hint": "⚠️ LEAVE EMPTY (recommended) - Using @@ALL causes output truncation bug. Leave empty to use default plugins for complete results.", "name": "plugins", "type": "text", "label": "Plugins", "format": "-Plugins {value}", "default": "", "required": false, "description": "Specify which plugins to run (optional, advanced)", "placeholder": ""}]}', 'LOW', 0);


--
-- Data for Name: ui_test; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ui_test VALUES (1, 'Google Search Test', 'Simple test to navigate to Google and verify title', 1, 'name: Google Search Test
description: Navigate to Google and verify title
config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: false
steps:
  - action: NAVIGATE_TO
    url: https://www.google.com
  - action: VALIDATE_TITLE
    expected: Google
  - action: TAKE_SCREENSHOT
', NULL, 'smoke,demo', 'ACTIVE', 'admin', '2026-01-24 07:55:36.48805', '2026-01-24 07:55:36.488055', 0, NULL, NULL, NULL);
INSERT INTO public.ui_test VALUES (2, 'OneCloudPlanet - Navigation & Contact Form', 'End-to-end test: validates homepage load, page navigation (prices, about, contacts), contact form fill, expansion panels, and footer links', NULL, 'name: OneCloudPlanet - Navigation & Contact Form
description: Validates homepage, navigation, and contact form

config:
  timeout: 15
  screenshotOnFailure: true
  continueOnFailure: false
  browser: chrome
  headless: true

variables:
  baseUrl: https://onecloudplanet.com/en

tests:
  - name: Homepage Load and Validation
    steps:
      - action: NAVIGATE_TO
        url: ${baseUrl}

      - action: WAIT_FOR_ELEMENT
        css: "button.v-btn.v-theme--light.v-btn--density-default"
        timeout: 10

      - action: VALIDATE_URL
        expected: "onecloudplanet.com/en"

      - action: TAKE_SCREENSHOT

      - action: VALIDATE_VISIBLE
        css: "body"

  - name: Navigate to Prices Page
    steps:
      - action: NAVIGATE_TO
        url: ${baseUrl}/prices

      - action: WAIT_FOR_ELEMENT
        css: "#input-50"
        timeout: 10

      - action: VALIDATE_URL
        expected: "/prices"

      - action: TAKE_SCREENSHOT

  - name: Navigate to About Company
    steps:
      - action: NAVIGATE_TO
        url: ${baseUrl}/about-company

      - action: WAIT_FOR_ELEMENT
        css: "#input-23"
        timeout: 10

      - action: VALIDATE_URL
        expected: "/about-company"

      - action: TAKE_SCREENSHOT

  - name: Contact Form View
    steps:
      - action: NAVIGATE_TO
        url: ${baseUrl}/contacts

      - action: WAIT_FOR_ELEMENT
        css: "#input-50"
        timeout: 10

      - action: VALIDATE_URL
        expected: "/contacts"

      - action: SCROLL_TO
        css: "#input-50"

      - action: TAKE_SCREENSHOT

      - action: VALIDATE_VISIBLE
        css: "button.primary-blue-btn[type=submit]"

  - name: Footer Links Validation
    steps:
      - action: NAVIGATE_TO
        url: ${baseUrl}

      - action: SCROLL_TO
        xpath: "//a[contains(text(), ''Site Map'')]"

      - action: VALIDATE_VISIBLE
        xpath: "//a[contains(text(), ''Site Map'')]"

      - action: TAKE_SCREENSHOT
', '[{"semanticName": "search_input", "tag": "input", "id": "input-23", "cssSelector": "#input-23", "type": "text"}, {"semanticName": "promo_banner", "tag": "a", "cssSelector": "a.custom-underline.d-sm-none.d-block.text-white"}, {"semanticName": "contact_name", "tag": "input", "id": "input-50", "cssSelector": "#input-50", "type": "text"}, {"semanticName": "contact_email", "tag": "input", "id": "input-54", "cssSelector": "#input-54", "type": "text"}, {"semanticName": "contact_phone", "tag": "input", "id": "input-57", "cssSelector": "#input-57", "type": "text"}, {"semanticName": "contact_message", "tag": "input", "id": "input-59", "cssSelector": "#input-59", "type": "text"}, {"semanticName": "submit_button", "tag": "button", "cssSelector": "button.primary-blue-btn[type=submit]", "type": "submit"}, {"semanticName": "expansion_panel", "tag": "button", "cssSelector": "button.v-expansion-panel-title", "type": "button"}, {"semanticName": "site_map_link", "tag": "a", "xpath": "//a[contains(text(), ''Site Map'')]"}, {"semanticName": "phone_link", "tag": "a", "cssSelector": "a[href*=tel]"}, {"semanticName": "email_link", "tag": "a", "cssSelector": "a[href*=mailto]"}]', 'smoke, navigation, contact-form, e2e', 'ACTIVE', 'admin', '2026-01-24 09:32:07.626846', '2026-01-26 02:23:29.299282', 8, NULL, NULL, NULL);
INSERT INTO public.ui_test VALUES (3, 'SauceDemo Login and Shopping Flow', 'Tests login, product browsing, add to cart, and checkout on SauceDemo', 1, 'name: SauceDemo Login and Shopping Flow
description: Complete e-commerce test flow

config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: false

variables:
  baseUrl: https://www.saucedemo.com
  username: standard_user
  password: secret_sauce

steps:
  # Login Flow
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: WAIT_FOR_VISIBLE
    css: "#user-name"
    timeout: 10

  - action: SEND_KEYS
    css: "#user-name"
    value: ${username}

  - action: SEND_KEYS
    css: "#password"
    value: ${password}

  - action: CLICK
    css: "#login-button"

  - action: WAIT_FOR_VISIBLE
    css: ".inventory_list"
    timeout: 10

  - action: VALIDATE_URL
    expected: ${baseUrl}/inventory.html

  - action: TAKE_SCREENSHOT
    prefix: inventory-page

  # Add first product to cart
  - action: CLICK
    css: "[data-test=''add-to-cart-sauce-labs-backpack'']"

  - action: WAIT_FOR_VISIBLE
    css: ".shopping_cart_badge"
    timeout: 5

  - action: VALIDATE_TEXT
    css: ".shopping_cart_badge"
    expected: "1"

  # Go to cart
  - action: CLICK
    css: "#shopping_cart_container a"

  - action: WAIT_FOR_VISIBLE
    css: "#cart_contents_container"
    timeout: 10

  - action: VALIDATE_VISIBLE
    css: ".cart_item"

  - action: TAKE_SCREENSHOT
    prefix: cart-page

  # Proceed to checkout
  - action: CLICK
    css: "#checkout"

  - action: WAIT_FOR_VISIBLE
    css: "#first-name"
    timeout: 10

  - action: SEND_KEYS
    css: "#first-name"
    value: Test

  - action: SEND_KEYS
    css: "#last-name"
    value: User

  - action: SEND_KEYS
    css: "#postal-code"
    value: "12345"

  - action: CLICK
    css: "#continue"

  - action: WAIT_FOR_VISIBLE
    css: ".summary_info"
    timeout: 10

  - action: TAKE_SCREENSHOT
    prefix: checkout-overview

  # Complete order
  - action: CLICK
    css: "#finish"

  - action: WAIT_FOR_VISIBLE
    css: ".complete-header"
    timeout: 10

  - action: VALIDATE_TEXT
    css: ".complete-header"
    expected: "Thank you for your order!"

  - action: TAKE_SCREENSHOT
    prefix: order-complete
', '[{"semanticName":"usernameField","tag":"input","id":"user-name","cssSelector":"#user-name","type":"text"},{"semanticName":"passwordField","tag":"input","id":"password","cssSelector":"#password","type":"password"},{"semanticName":"loginButton","tag":"input","id":"login-button","cssSelector":"#login-button","type":"submit"},{"semanticName":"inventoryList","tag":"div","cssSelector":".inventory_list"},{"semanticName":"addBackpackToCart","tag":"button","cssSelector":"[data-test=''add-to-cart-sauce-labs-backpack'']"},{"semanticName":"cartBadge","tag":"span","cssSelector":".shopping_cart_badge"},{"semanticName":"cartLink","tag":"a","cssSelector":"#shopping_cart_container a"},{"semanticName":"cartContents","tag":"div","id":"cart_contents_container","cssSelector":"#cart_contents_container"},{"semanticName":"cartItem","tag":"div","cssSelector":".cart_item"},{"semanticName":"checkoutButton","tag":"button","id":"checkout","cssSelector":"#checkout"},{"semanticName":"firstNameField","tag":"input","id":"first-name","cssSelector":"#first-name"},{"semanticName":"lastNameField","tag":"input","id":"last-name","cssSelector":"#last-name"},{"semanticName":"postalCodeField","tag":"input","id":"postal-code","cssSelector":"#postal-code"},{"semanticName":"continueButton","tag":"input","id":"continue","cssSelector":"#continue"},{"semanticName":"finishButton","tag":"button","id":"finish","cssSelector":"#finish"},{"semanticName":"completeHeader","tag":"h2","cssSelector":".complete-header"}]', 'saucedemo, e-commerce, login, checkout, smoke', 'ACTIVE', 'admin', '2026-01-27 04:15:33.609375', '2026-01-27 04:24:21.755881', 1, NULL, NULL, NULL);
INSERT INTO public.ui_test VALUES (4, 'Lingo - Page Navigation & Screenshots', 'Navigate key Lingo pages, validate titles and capture screenshots', 1, 'name: Lingo - Page Navigation & Screenshots
description: Navigate key Lingo pages, validate titles and capture screenshots
config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: true
  browser: chrome
  headless: true

variables:
  baseUrl: https://lingo.com

steps:
  # 1. Navigate to home page
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: VALIDATE_TITLE
    expected: "Phone, Cloud, Broadband, Security and Managed Services for Businesses | Lingo"

  - action: TAKE_SCREENSHOT

  # 2. Navigate to Cloud Business Phone page
  - action: NAVIGATE_TO
    url: ${baseUrl}/cloud-business-phone

  - action: VALIDATE_TITLE
    expected: "Cloud Business Phone \u2013 Phone, Cloud, Broadband, Security and Managed Services for Businesses | Lingo"

  - action: WAIT_FOR_ELEMENT
    css: "h1"
    timeout: 10

  - action: TAKE_SCREENSHOT

  # 3. Navigate to Security page
  - action: NAVIGATE_TO
    url: ${baseUrl}/security

  - action: VALIDATE_TITLE
    expected: "Security \u2013 Phone, Cloud, Broadband, Security and Managed Services for Businesses | Lingo"

  - action: WAIT_FOR_ELEMENT
    css: "h1"
    timeout: 10

  - action: TAKE_SCREENSHOT

  # 4. Navigate to About page
  - action: NAVIGATE_TO
    url: ${baseUrl}/meet-lingo

  - action: VALIDATE_TITLE
    expected: "About \u2013 Phone, Cloud, Broadband, Security and Managed Services for Businesses | Lingo"

  - action: TAKE_SCREENSHOT
', NULL, 'development', 'ACTIVE', 'admin', '2026-01-29 03:30:37.785828', '2026-01-29 04:06:49.689142', 2, NULL, NULL, NULL);
INSERT INTO public.ui_test VALUES (5, 'SauceDemo - Login & Inventory Assertions', 'Validates login flow and inventory page elements', 1, 'name: SauceDemo - Login & Inventory Assertions
description: Validates login flow and inventory page elements

config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: true

variables:
  baseUrl: https://www.saucedemo.com
  username: standard_user
  password: secret_sauce

steps:
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: VALIDATE_TITLE
    expected: "Swag Labs"

  - action: WAIT_FOR_VISIBLE
    css: "#user-name"
    timeout: 10

  - action: VALIDATE_VISIBLE
    css: "#login-button"

  - action: TAKE_SCREENSHOT
    prefix: login-page

  - action: SEND_KEYS
    css: "#user-name"
    value: ${username}

  - action: SEND_KEYS
    css: "#password"
    value: ${password}

  - action: CLICK
    css: "#login-button"

  - action: WAIT_FOR_VISIBLE
    css: ".inventory_list"
    timeout: 10

  - action: VALIDATE_URL
    expected: ${baseUrl}/inventory.html

  - action: VALIDATE_TITLE
    expected: "Swag Labs"

  - action: VALIDATE_VISIBLE
    css: ".header_secondary_container .title"

  - action: VALIDATE_TEXT
    css: ".header_secondary_container .title"
    expected: "Products"

  - action: VALIDATE_VISIBLE
    css: "[data-test=''add-to-cart-sauce-labs-backpack'']"

  - action: TAKE_SCREENSHOT
    prefix: inventory-verified
', NULL, NULL, 'ACTIVE', 'admin', '2026-01-31 03:58:17.424146', '2026-01-31 03:58:17.424147', 0, 'SauceDemo Demo', 'Login & Inventory', NULL);
INSERT INTO public.ui_test VALUES (6, 'SauceDemo - Cart & Product Detail', 'Tests product detail navigation and cart functionality', 1, 'name: SauceDemo - Cart & Product Detail
description: Tests product detail navigation and cart functionality

config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: true

variables:
  baseUrl: https://www.saucedemo.com
  username: standard_user
  password: secret_sauce

steps:
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: WAIT_FOR_VISIBLE
    css: "#user-name"
    timeout: 10

  - action: SEND_KEYS
    css: "#user-name"
    value: ${username}

  - action: SEND_KEYS
    css: "#password"
    value: ${password}

  - action: CLICK
    css: "#login-button"

  - action: WAIT_FOR_VISIBLE
    css: ".inventory_list"
    timeout: 10

  - action: CLICK
    css: "#item_4_title_link"

  - action: WAIT_FOR_VISIBLE
    css: ".inventory_details_name"
    timeout: 10

  - action: VALIDATE_TEXT
    css: ".inventory_details_name"
    expected: "Sauce Labs Backpack"

  - action: VALIDATE_VISIBLE
    css: ".inventory_details_price"

  - action: TAKE_SCREENSHOT
    prefix: product-detail

  - action: CLICK
    css: "[data-test=''add-to-cart'']"

  - action: VALIDATE_TEXT
    css: ".shopping_cart_badge"
    expected: "1"

  - action: CLICK
    css: "#shopping_cart_container a"

  - action: WAIT_FOR_VISIBLE
    css: ".cart_item"
    timeout: 10

  - action: VALIDATE_TEXT
    css: ".cart_quantity"
    expected: "1"

  - action: VALIDATE_TEXT
    css: ".inventory_item_name"
    expected: "Sauce Labs Backpack"

  - action: TAKE_SCREENSHOT
    prefix: cart-verified
', NULL, NULL, 'ACTIVE', 'admin', '2026-01-31 03:58:17.438967', '2026-01-31 03:58:17.438968', 0, 'SauceDemo Demo', 'Cart & Products', NULL);
INSERT INTO public.ui_test VALUES (7, 'SauceDemo - Title Regression (WILL FAIL)', 'Intentionally wrong assertions to demonstrate failure reporting', 1, 'name: SauceDemo - Page Title Regression (WILL FAIL)
description: Regression test with intentionally wrong title assertion to demo failure

config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: true

variables:
  baseUrl: https://www.saucedemo.com
  username: standard_user
  password: secret_sauce

steps:
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: VALIDATE_TITLE
    expected: "Swag Labs"

  - action: WAIT_FOR_VISIBLE
    css: "#user-name"
    timeout: 10

  - action: SEND_KEYS
    css: "#user-name"
    value: ${username}

  - action: SEND_KEYS
    css: "#password"
    value: ${password}

  - action: CLICK
    css: "#login-button"

  - action: WAIT_FOR_VISIBLE
    css: ".inventory_list"
    timeout: 10

  - action: TAKE_SCREENSHOT
    prefix: before-wrong-assertion

  # INTENTIONAL FAILURE: title is "Swag Labs" not "Amazon Store"
  - action: VALIDATE_TITLE
    expected: "Amazon Store"

  # INTENTIONAL FAILURE: products heading says "Products" not "Shop All Items"
  - action: VALIDATE_TEXT
    css: ".header_secondary_container .title"
    expected: "Shop All Items"

  - action: TAKE_SCREENSHOT
    prefix: after-wrong-assertion
', NULL, NULL, 'ACTIVE', 'admin', '2026-01-31 03:58:17.450754', '2026-01-31 03:58:17.450755', 0, 'SauceDemo Demo', 'Regression', NULL);
INSERT INTO public.ui_test VALUES (8, 'Walmart - Grocery Navigation & Assertions', 'Navigate from homepage to Departments then Grocery page, verify page title and key elements', 1, 'name: Walmart - Grocery Navigation & Assertions
description: Navigate to Departments > Groceries page and validate title, heading, elements

config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: true

variables:
  baseUrl: ""

steps:
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: VALIDATE_TITLE
    expected: "Walmart | Save Money. Live better."

  - action: TAKE_SCREENSHOT
    prefix: walmart-homepage

  - action: WAIT_FOR_VISIBLE
    css: "a[href*=''/all-departments''], a[href*=''departments'']"
    timeout: 15

  - action: NAVIGATE_TO
    url: ${baseUrl}/all-departments

  - action: WAIT_FOR_VISIBLE
    css: "body"
    timeout: 15

  - action: TAKE_SCREENSHOT
    prefix: all-departments

  - action: NAVIGATE_TO
    url: ${baseUrl}/browse/grocery/976759

  - action: WAIT_FOR_VISIBLE
    css: "body"
    timeout: 15

  - action: TAKE_SCREENSHOT
    prefix: grocery-page

  - action: VALIDATE_URL_CONTAINS
    expected: "grocery"

  - action: VALIDATE_ELEMENT_EXISTS
    css: "header, [role=''banner'']"

  - action: VALIDATE_ELEMENT_EXISTS
    css: "nav, [role=''navigation'']"

  - action: TAKE_SCREENSHOT
    prefix: grocery-final
', NULL, NULL, 'ACTIVE', 'admin', '2026-01-31 05:27:58.685722', '2026-01-31 05:27:58.685726', 0, 'Walmart Demo for Sachin', 'Navigation', NULL);
INSERT INTO public.ui_test VALUES (9, 'Walmart - Pharmacy Services Page', 'Navigate to Services > Pharmacy page and validate title, headings, and key page elements', 1, 'name: Walmart - Pharmacy Services Page
description: Navigate to Pharmacy page and validate title and page content

config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: true

variables:
  baseUrl: ""

steps:
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: VALIDATE_TITLE
    expected: "Walmart | Save Money. Live better."

  - action: TAKE_SCREENSHOT
    prefix: homepage-before-pharmacy

  - action: NAVIGATE_TO
    url: ${baseUrl}/cp/pharmacy/5431

  - action: WAIT_FOR_VISIBLE
    css: "body"
    timeout: 15

  - action: TAKE_SCREENSHOT
    prefix: pharmacy-page

  - action: VALIDATE_URL_CONTAINS
    expected: "pharmacy"

  - action: VALIDATE_ELEMENT_EXISTS
    css: "header, [role=''banner'']"

  - action: VALIDATE_ELEMENT_EXISTS
    css: "img, svg"

  - action: VALIDATE_ELEMENT_EXISTS
    css: "footer, [role=''contentinfo'']"

  - action: TAKE_SCREENSHOT
    prefix: pharmacy-final
', NULL, NULL, 'ACTIVE', 'admin', '2026-01-31 05:27:58.740502', '2026-01-31 05:27:58.740506', 0, 'Walmart Demo for Sachin', 'Services', NULL);
INSERT INTO public.ui_test VALUES (10, 'Walmart - Intentional Failures (WILL FAIL)', 'Homepage assertions with intentionally wrong expected values to demonstrate failure reporting', 1, 'name: Walmart - Intentional Failures (WILL FAIL)
description: Tests with deliberately wrong assertions to show failure reporting

config:
  timeout: 30
  screenshotOnFailure: true
  continueOnFailure: true

variables:
  baseUrl: ""

steps:
  - action: NAVIGATE_TO
    url: ${baseUrl}

  - action: WAIT_FOR_VISIBLE
    css: "body"
    timeout: 15

  - action: TAKE_SCREENSHOT
    prefix: before-wrong-assertions

  # INTENTIONAL FAILURE: Title is ''Walmart | Save Money. Live better.'' not ''Target | Expect More. Pay Less.''
  - action: VALIDATE_TITLE
    expected: "Target | Expect More. Pay Less."

  # INTENTIONAL FAILURE: This CSS selector does not exist on Walmart
  - action: VALIDATE_ELEMENT_EXISTS
    css: "#amazon-prime-banner"

  - action: VALIDATE_ELEMENT_EXISTS
    css: "header, [role=''banner'']"

  - action: VALIDATE_URL_CONTAINS
    expected: "walmart.com"

  - action: TAKE_SCREENSHOT
    prefix: after-wrong-assertions
', NULL, NULL, 'ACTIVE', 'admin', '2026-01-31 05:27:58.799677', '2026-01-31 05:27:58.79968', 0, 'Walmart Demo for Sachin', 'Regression', NULL);


--
-- Data for Name: ui_test_suite; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ui_test_suite VALUES (1, 'suite 1', 'suite 1', 1, false, 'ACTIVE', '2026-01-30 22:26:44.139111', '2026-01-30 23:15:39.330218', 'admin', 'admin', 1);
INSERT INTO public.ui_test_suite VALUES (2, 'SauceDemo Staging Demo Suite', 'Demo suite: login assertions, cart flow, and intentional failure', 1, false, 'ACTIVE', '2026-01-31 03:58:47.942721', '2026-01-31 03:58:47.942723', 'admin', NULL, 0);
INSERT INTO public.ui_test_suite VALUES (3, 'Walmart demo Sachin', 'Demo test suite for Walmart.com - Navigation, Services, and Regression tests', 1, false, 'ACTIVE', '2026-01-31 05:28:22.199986', '2026-01-31 05:28:22.199997', 'admin', NULL, 0);


--
-- Data for Name: ui_test_suite_item; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ui_test_suite_item VALUES (10, 1, 4, 0, 1, true, NULL);
INSERT INTO public.ui_test_suite_item VALUES (11, 1, 3, 1, 1, true, NULL);
INSERT INTO public.ui_test_suite_item VALUES (12, 1, 1, 2, 1, true, NULL);
INSERT INTO public.ui_test_suite_item VALUES (13, 2, 5, 0, 1, true, 7);
INSERT INTO public.ui_test_suite_item VALUES (14, 2, 6, 1, 1, true, 7);
INSERT INTO public.ui_test_suite_item VALUES (15, 2, 7, 2, 1, true, 7);
INSERT INTO public.ui_test_suite_item VALUES (16, 3, 8, 0, 1, true, 8);
INSERT INTO public.ui_test_suite_item VALUES (17, 3, 9, 1, 1, true, 8);
INSERT INTO public.ui_test_suite_item VALUES (18, 3, 10, 2, 1, true, 8);


--
-- Data for Name: user_roles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.user_roles VALUES (1, 'VIEWER', 0);
INSERT INTO public.user_roles VALUES (1, 'ADMIN', 0);
INSERT INTO public.user_roles VALUES (1, 'ANALYST', 0);


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users VALUES (1, '2026-01-02 06:49:49.387', '2026-01-29 03:54:19.704', 'admin', 'admin@localhost', '$2a$10$.grjzh4ZC05E0VrVrLAbn.x9tAm5r.DSSuR8.4lTHbYjtEyASpsAm', 'Admin User', true, false, 1769836252083, 107);


--
-- Name: agent_registration_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.agent_registration_id_seq', 1, false);


--
-- Name: agent_token_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.agent_token_id_seq', 1, false);


--
-- Name: alert_definition_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.alert_definition_id_seq', 27, true);


--
-- Name: alert_instance_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.alert_instance_id_seq', 1, false);


--
-- Name: api_payload_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_payload_id_seq', 45, true);


--
-- Name: api_scan_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_scan_history_id_seq', 14, true);


--
-- Name: api_scenario_executions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_scenario_executions_id_seq', 29, true);


--
-- Name: api_scenario_extractions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_scenario_extractions_id_seq', 7, true);


--
-- Name: api_scenario_step_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_scenario_step_results_id_seq', 154, true);


--
-- Name: api_scenario_steps_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_scenario_steps_id_seq', 42, true);


--
-- Name: api_scenarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.api_scenarios_id_seq', 14, true);


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 591, true);


--
-- Name: custom_script_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.custom_script_id_seq', 8, true);


--
-- Name: environment_services_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.environment_services_id_seq', 8, true);


--
-- Name: environments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.environments_id_seq', 3, true);


--
-- Name: header_injection_presets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.header_injection_presets_id_seq', 6, true);


--
-- Name: license_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.license_id_seq', 1, true);


--
-- Name: performance_scenarios_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.performance_scenarios_id_seq', 13, true);


--
-- Name: project_applications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.project_applications_id_seq', 2, true);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.projects_id_seq', 1, true);


--
-- Name: scan_comparison_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_comparison_id_seq', 1, false);


--
-- Name: scan_execution_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_execution_id_seq', 5, true);


--
-- Name: scan_group_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_group_id_seq', 1, true);


--
-- Name: scan_group_templates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_group_templates_id_seq', 2, true);


--
-- Name: scan_job_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_job_id_seq', 225, true);


--
-- Name: scan_job_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_job_item_id_seq', 256, true);


--
-- Name: scan_preset_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_preset_id_seq', 10, true);


--
-- Name: scan_schedule_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_schedule_id_seq', 1, false);


--
-- Name: scan_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.scan_template_id_seq', 80, true);


--
-- Name: ui_test_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ui_test_id_seq', 10, true);


--
-- Name: ui_test_suite_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ui_test_suite_id_seq', 3, true);


--
-- Name: ui_test_suite_item_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ui_test_suite_item_id_seq', 18, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 1, true);


--
-- Name: agent_registration agent_registration_agent_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_registration
    ADD CONSTRAINT agent_registration_agent_id_key UNIQUE (agent_id);


--
-- Name: agent_registration agent_registration_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_registration
    ADD CONSTRAINT agent_registration_pkey PRIMARY KEY (id);


--
-- Name: agent_token agent_token_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_token
    ADD CONSTRAINT agent_token_pkey PRIMARY KEY (id);


--
-- Name: agent_token agent_token_token_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_token
    ADD CONSTRAINT agent_token_token_id_key UNIQUE (token_id);


--
-- Name: alert_definition alert_definition_alert_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_definition
    ADD CONSTRAINT alert_definition_alert_name_key UNIQUE (alert_name);


--
-- Name: alert_definition alert_definition_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_definition
    ADD CONSTRAINT alert_definition_pkey PRIMARY KEY (id);


--
-- Name: alert_instance alert_instance_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_instance
    ADD CONSTRAINT alert_instance_pkey PRIMARY KEY (id);


--
-- Name: api_payload api_payload_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_payload
    ADD CONSTRAINT api_payload_pkey PRIMARY KEY (id);


--
-- Name: api_scan_history api_scan_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history
    ADD CONSTRAINT api_scan_history_pkey PRIMARY KEY (id);


--
-- Name: api_scenario_executions api_scenario_executions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_executions
    ADD CONSTRAINT api_scenario_executions_pkey PRIMARY KEY (id);


--
-- Name: api_scenario_extractions api_scenario_extractions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_extractions
    ADD CONSTRAINT api_scenario_extractions_pkey PRIMARY KEY (id);


--
-- Name: api_scenario_step_results api_scenario_step_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_step_results
    ADD CONSTRAINT api_scenario_step_results_pkey PRIMARY KEY (id);


--
-- Name: api_scenario_steps api_scenario_steps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_steps
    ADD CONSTRAINT api_scenario_steps_pkey PRIMARY KEY (id);


--
-- Name: api_scenario_steps api_scenario_steps_scenario_id_step_order_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_steps
    ADD CONSTRAINT api_scenario_steps_scenario_id_step_order_key UNIQUE (scenario_id, step_order);


--
-- Name: api_scenarios api_scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenarios
    ADD CONSTRAINT api_scenarios_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: custom_script custom_script_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_script
    ADD CONSTRAINT custom_script_pkey PRIMARY KEY (id);


--
-- Name: custom_script custom_script_tool_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_script
    ADD CONSTRAINT custom_script_tool_name_key UNIQUE (tool_name);


--
-- Name: environment_targets environment_services_environment_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environment_targets
    ADD CONSTRAINT environment_services_environment_id_name_key UNIQUE (environment_id, name);


--
-- Name: environment_targets environment_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environment_targets
    ADD CONSTRAINT environment_services_pkey PRIMARY KEY (id);


--
-- Name: environments environments_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT environments_name_key UNIQUE (name);


--
-- Name: environments environments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT environments_pkey PRIMARY KEY (id);


--
-- Name: header_injection_presets header_injection_presets_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.header_injection_presets
    ADD CONSTRAINT header_injection_presets_name_key UNIQUE (name);


--
-- Name: header_injection_presets header_injection_presets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.header_injection_presets
    ADD CONSTRAINT header_injection_presets_pkey PRIMARY KEY (id);


--
-- Name: license license_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license
    ADD CONSTRAINT license_pkey PRIMARY KEY (id);


--
-- Name: performance_scenarios performance_scenarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT performance_scenarios_pkey PRIMARY KEY (id);


--
-- Name: project_applications project_applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_applications
    ADD CONSTRAINT project_applications_pkey PRIMARY KEY (id);


--
-- Name: project_applications project_applications_project_id_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_applications
    ADD CONSTRAINT project_applications_project_id_name_key UNIQUE (project_id, name);


--
-- Name: projects projects_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_name_key UNIQUE (name);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: scan_comparison scan_comparison_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_comparison
    ADD CONSTRAINT scan_comparison_pkey PRIMARY KEY (id);


--
-- Name: scan_execution scan_execution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_execution
    ADD CONSTRAINT scan_execution_pkey PRIMARY KEY (id);


--
-- Name: scan_group scan_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group
    ADD CONSTRAINT scan_group_pkey PRIMARY KEY (id);


--
-- Name: scan_group_templates scan_group_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group_templates
    ADD CONSTRAINT scan_group_templates_pkey PRIMARY KEY (id);


--
-- Name: scan_group_templates scan_group_templates_scan_group_id_scan_template_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group_templates
    ADD CONSTRAINT scan_group_templates_scan_group_id_scan_template_id_key UNIQUE (scan_group_id, scan_template_id);


--
-- Name: scan_job_item scan_job_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job_item
    ADD CONSTRAINT scan_job_item_pkey PRIMARY KEY (id);


--
-- Name: scan_job_item scan_job_item_scan_job_id_scan_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job_item
    ADD CONSTRAINT scan_job_item_scan_job_id_scan_id_key UNIQUE (scan_job_id, scan_id);


--
-- Name: scan_job scan_job_job_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_job_id_key UNIQUE (job_id);


--
-- Name: scan_job scan_job_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_pkey PRIMARY KEY (id);


--
-- Name: scan_preset scan_preset_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_preset
    ADD CONSTRAINT scan_preset_pkey PRIMARY KEY (id);


--
-- Name: scan_schedule scan_schedule_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_schedule
    ADD CONSTRAINT scan_schedule_pkey PRIMARY KEY (id);


--
-- Name: scan_template scan_template_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_template
    ADD CONSTRAINT scan_template_pkey PRIMARY KEY (id);


--
-- Name: ui_test ui_test_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test
    ADD CONSTRAINT ui_test_pkey PRIMARY KEY (id);


--
-- Name: ui_test_suite_item ui_test_suite_item_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite_item
    ADD CONSTRAINT ui_test_suite_item_pkey PRIMARY KEY (id);


--
-- Name: ui_test_suite_item ui_test_suite_item_suite_id_ui_test_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite_item
    ADD CONSTRAINT ui_test_suite_item_suite_id_ui_test_id_key UNIQUE (suite_id, ui_test_id);


--
-- Name: ui_test_suite ui_test_suite_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite
    ADD CONSTRAINT ui_test_suite_pkey PRIMARY KEY (id);


--
-- Name: scan_group_templates uk2ndquv01r7p0obphjis6assk9; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group_templates
    ADD CONSTRAINT uk2ndquv01r7p0obphjis6assk9 UNIQUE (scan_group_id, scan_template_id);


--
-- Name: scan_template uk2xwpfuowp5jygej0odes7aqx9; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_template
    ADD CONSTRAINT uk2xwpfuowp5jygej0odes7aqx9 UNIQUE (category, test_type, tool_name, name);


--
-- Name: scan_comparison uk3g8mjltvctm24hkbwr7qetwwm; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_comparison
    ADD CONSTRAINT uk3g8mjltvctm24hkbwr7qetwwm UNIQUE (baseline_scan_id, current_scan_id);


--
-- Name: users uk6dotkott2kjsp8vw4d0m25fb7; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk6dotkott2kjsp8vw4d0m25fb7 UNIQUE (email);


--
-- Name: alert_definition uko9r1mlxcrwl6vec9jve5glo9b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_definition
    ADD CONSTRAINT uko9r1mlxcrwl6vec9jve5glo9b UNIQUE (alert_name);


--
-- Name: users ukr43af9ap4edm43mmtq01oddj6; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT ukr43af9ap4edm43mmtq01oddj6 UNIQUE (username);


--
-- Name: scan_preset ukrbei2ecy7vpjtkqh3ofel9n7d; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_preset
    ADD CONSTRAINT ukrbei2ecy7vpjtkqh3ofel9n7d UNIQUE (name, created_by);


--
-- Name: scan_preset unique_preset_name_per_user; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_preset
    ADD CONSTRAINT unique_preset_name_per_user UNIQUE (name, created_by);


--
-- Name: scan_comparison uq_scan_comparison; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_comparison
    ADD CONSTRAINT uq_scan_comparison UNIQUE (baseline_scan_id, current_scan_id);


--
-- Name: scan_template uq_scan_template; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_template
    ADD CONSTRAINT uq_scan_template UNIQUE (category, test_type, tool_name, name);


--
-- Name: user_roles user_roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_pkey PRIMARY KEY (user_id, role);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: idx_agent_reg_last_seen; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_reg_last_seen ON public.agent_registration USING btree (last_seen_at DESC);


--
-- Name: idx_agent_reg_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_reg_status ON public.agent_registration USING btree (status);


--
-- Name: idx_agent_token_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_token_active ON public.agent_token USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_agent_token_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_token_customer ON public.agent_token USING btree (customer_id, environment);


--
-- Name: idx_agent_token_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_agent_token_expires ON public.agent_token USING btree (expires_at) WHERE (is_active = true);


--
-- Name: idx_alert_def_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_def_enabled ON public.alert_definition USING btree (enabled) WHERE (enabled = true);


--
-- Name: idx_alert_def_template; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_def_template ON public.alert_definition USING btree (scan_template_id);


--
-- Name: idx_alert_inst_definition; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_inst_definition ON public.alert_instance USING btree (alert_definition_id);


--
-- Name: idx_alert_inst_scan; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_inst_scan ON public.alert_instance USING btree (scan_execution_id);


--
-- Name: idx_alert_inst_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_inst_status ON public.alert_instance USING btree (status);


--
-- Name: idx_alert_inst_triggered; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_alert_inst_triggered ON public.alert_instance USING btree (triggered_at DESC);


--
-- Name: idx_api_payload_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_payload_category ON public.api_payload USING btree (category);


--
-- Name: idx_api_payload_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_payload_enabled ON public.api_payload USING btree (enabled);


--
-- Name: idx_api_scan_history_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_created ON public.api_scan_history USING btree (created_at DESC);


--
-- Name: idx_api_scan_history_env; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_env ON public.api_scan_history USING btree (env);


--
-- Name: idx_api_scan_history_environment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_environment ON public.api_scan_history USING btree (environment_id);


--
-- Name: idx_api_scan_history_findings; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_findings ON public.api_scan_history USING btree (findings_count) WHERE (findings_count > 0);


--
-- Name: idx_api_scan_history_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_project ON public.api_scan_history USING btree (project_id);


--
-- Name: idx_api_scan_history_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_service ON public.api_scan_history USING btree (service_id);


--
-- Name: idx_api_scan_history_summary; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_summary ON public.api_scan_history USING gin (summary);


--
-- Name: idx_api_scan_history_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_tags ON public.api_scan_history USING gin (tags);


--
-- Name: idx_api_scan_history_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_target ON public.api_scan_history USING btree (target_url);


--
-- Name: idx_api_scan_history_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scan_history_user ON public.api_scan_history USING btree (user_id);


--
-- Name: idx_api_scenario_executions_env; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_env ON public.api_scenario_executions USING btree (environment_id);


--
-- Name: idx_api_scenario_executions_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_project ON public.api_scenario_executions USING btree (project_id);


--
-- Name: idx_api_scenario_executions_scenario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_scenario ON public.api_scenario_executions USING btree (scenario_id);


--
-- Name: idx_api_scenario_executions_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_service ON public.api_scenario_executions USING btree (service_id);


--
-- Name: idx_api_scenario_executions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_status ON public.api_scenario_executions USING btree (status);


--
-- Name: idx_api_scenario_executions_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_tags ON public.api_scenario_executions USING gin (tags);


--
-- Name: idx_api_scenario_extractions_step; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_extractions_step ON public.api_scenario_extractions USING btree (step_id);


--
-- Name: idx_api_scenario_step_results_execution; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_step_results_execution ON public.api_scenario_step_results USING btree (execution_id);


--
-- Name: idx_api_scenario_steps_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_steps_order ON public.api_scenario_steps USING btree (scenario_id, step_order);


--
-- Name: idx_api_scenario_steps_scenario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_steps_scenario ON public.api_scenario_steps USING btree (scenario_id);


--
-- Name: idx_api_scenarios_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_active ON public.api_scenarios USING btree (is_active);


--
-- Name: idx_api_scenarios_environment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_environment ON public.api_scenarios USING btree (environment_id);


--
-- Name: idx_api_scenarios_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_project ON public.api_scenarios USING btree (project_id);


--
-- Name: idx_api_scenarios_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_service ON public.api_scenarios USING btree (service_id);


--
-- Name: idx_audit_action; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_action ON public.audit_log USING btree (action);


--
-- Name: idx_audit_action_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_action_timestamp ON public.audit_log USING btree (action, "timestamp" DESC);


--
-- Name: idx_audit_entity_lookup; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_entity_lookup ON public.audit_log USING btree (entity_type, entity_id);


--
-- Name: idx_audit_entity_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_entity_type ON public.audit_log USING btree (entity_type);


--
-- Name: idx_audit_ip_address; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_ip_address ON public.audit_log USING btree (ip_address);


--
-- Name: idx_audit_success; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_success ON public.audit_log USING btree (success);


--
-- Name: idx_audit_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_timestamp ON public.audit_log USING btree ("timestamp");


--
-- Name: idx_audit_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_user_id ON public.audit_log USING btree (user_id);


--
-- Name: idx_audit_user_timestamp; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_user_timestamp ON public.audit_log USING btree (user_id, "timestamp" DESC);


--
-- Name: idx_audit_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_audit_username ON public.audit_log USING btree (username);


--
-- Name: idx_custom_script_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_script_category ON public.custom_script USING btree (category);


--
-- Name: idx_custom_script_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_script_status ON public.custom_script USING btree (status);


--
-- Name: idx_custom_script_tool_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_script_tool_name ON public.custom_script USING btree (tool_name);


--
-- Name: idx_custom_script_uploaded_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_script_uploaded_by ON public.custom_script USING btree (uploaded_by);


--
-- Name: idx_env_targets_env_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_env_targets_env_id ON public.environment_targets USING btree (environment_id);


--
-- Name: idx_env_targets_host; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_env_targets_host ON public.environment_targets USING btree (host);


--
-- Name: idx_env_targets_ip; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_env_targets_ip ON public.environment_targets USING btree (ip);


--
-- Name: idx_env_targets_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_env_targets_type ON public.environment_targets USING btree (target_type);


--
-- Name: idx_environments_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_environments_active ON public.environments USING btree (is_active);


--
-- Name: idx_environments_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_environments_name ON public.environments USING btree (name);


--
-- Name: idx_environments_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_environments_project ON public.environments USING btree (project_id);


--
-- Name: idx_header_presets_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_header_presets_active ON public.header_injection_presets USING btree (is_active);


--
-- Name: idx_header_presets_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_header_presets_name ON public.header_injection_presets USING btree (name);


--
-- Name: idx_header_presets_system; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_header_presets_system ON public.header_injection_presets USING btree (is_system);


--
-- Name: idx_perf_scenario_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_active ON public.performance_scenarios USING btree (is_active);


--
-- Name: idx_perf_scenario_environment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_environment ON public.performance_scenarios USING btree (environment_id);


--
-- Name: idx_perf_scenario_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_project ON public.performance_scenarios USING btree (project_id);


--
-- Name: idx_perf_scenario_service; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_service ON public.performance_scenarios USING btree (service_id);


--
-- Name: idx_perf_scenario_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_source ON public.performance_scenarios USING btree (source_scenario_id) WHERE (source_scenario_id IS NOT NULL);


--
-- Name: idx_perf_scenario_test_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_test_type ON public.performance_scenarios USING btree (test_type);


--
-- Name: idx_project_applications_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_applications_active ON public.project_applications USING btree (is_active);


--
-- Name: idx_project_applications_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_applications_project ON public.project_applications USING btree (project_id);


--
-- Name: idx_projects_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_active ON public.projects USING btree (is_active);


--
-- Name: idx_projects_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_projects_name ON public.projects USING btree (name);


--
-- Name: idx_scan_comp_baseline; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_comp_baseline ON public.scan_comparison USING btree (baseline_scan_id);


--
-- Name: idx_scan_comp_current; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_comp_current ON public.scan_comparison USING btree (current_scan_id);


--
-- Name: idx_scan_comp_state; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_comp_state ON public.scan_comparison USING btree (state);


--
-- Name: idx_scan_exec_baseline; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_exec_baseline ON public.scan_execution USING btree (scan_template_id, target, is_baseline) WHERE (is_baseline = true);


--
-- Name: idx_scan_exec_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_exec_created ON public.scan_execution USING btree (created_at DESC);


--
-- Name: idx_scan_exec_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_exec_group ON public.scan_execution USING btree (scan_group_id);


--
-- Name: idx_scan_exec_result_gin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_exec_result_gin ON public.scan_execution USING gin (execution_result jsonb_path_ops);


--
-- Name: idx_scan_exec_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_exec_status ON public.scan_execution USING btree (status);


--
-- Name: idx_scan_exec_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_exec_target ON public.scan_execution USING btree (target);


--
-- Name: idx_scan_exec_template; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_exec_template ON public.scan_execution USING btree (scan_template_id);


--
-- Name: idx_scan_group_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_group_enabled ON public.scan_group USING btree (enabled);


--
-- Name: idx_scan_group_env; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_group_env ON public.scan_group USING btree (environment);


--
-- Name: idx_scan_group_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_group_name ON public.scan_group USING btree (name);


--
-- Name: idx_scan_job_api_scenario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_api_scenario ON public.scan_job USING btree (api_scenario_id);


--
-- Name: idx_scan_job_claimed_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_claimed_by ON public.scan_job USING btree (claimed_by);


--
-- Name: idx_scan_job_customer; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_customer ON public.scan_job USING btree (customer_id, environment);


--
-- Name: idx_scan_job_environment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_environment ON public.scan_job USING btree (environment_id);


--
-- Name: idx_scan_job_item_job; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_item_job ON public.scan_job_item USING btree (scan_job_id);


--
-- Name: idx_scan_job_item_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_item_status ON public.scan_job_item USING btree (status);


--
-- Name: idx_scan_job_item_tool; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_item_tool ON public.scan_job_item USING btree (tool_name);


--
-- Name: idx_scan_job_pending; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_pending ON public.scan_job USING btree (status, priority DESC, created_at) WHERE ((status)::text = 'PENDING'::text);


--
-- Name: idx_scan_job_performance_scenario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_performance_scenario ON public.scan_job USING btree (performance_scenario_id);


--
-- Name: idx_scan_job_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_priority ON public.scan_job USING btree (priority DESC);


--
-- Name: idx_scan_job_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_project ON public.scan_job USING btree (project_id);


--
-- Name: idx_scan_job_retry; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_retry ON public.scan_job USING btree (next_retry_at) WHERE (((status)::text = 'FAILED'::text) AND (retry_count < max_retries));


--
-- Name: idx_scan_job_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_status ON public.scan_job USING btree (status);


--
-- Name: idx_scan_job_suite_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_suite_id ON public.scan_job USING btree (ui_test_suite_id);


--
-- Name: idx_scan_job_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_target ON public.scan_job USING btree (target_id);


--
-- Name: idx_scan_preset_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_preset_category ON public.scan_preset USING btree (category);


--
-- Name: idx_scan_preset_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_preset_created_by ON public.scan_preset USING btree (created_by);


--
-- Name: idx_scan_preset_is_favorite; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_preset_is_favorite ON public.scan_preset USING btree (is_favorite);


--
-- Name: idx_scan_preset_is_public; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_preset_is_public ON public.scan_preset USING btree (is_public);


--
-- Name: idx_scan_preset_template; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_preset_template ON public.scan_preset USING btree (scan_template_id);


--
-- Name: idx_scan_schedule_next_run; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_schedule_next_run ON public.scan_schedule USING btree (next_run_at) WHERE (enabled = true);


--
-- Name: idx_scan_schedule_template; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_schedule_template ON public.scan_schedule USING btree (scan_template_id);


--
-- Name: idx_scan_template_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_template_category ON public.scan_template USING btree (category, test_type);


--
-- Name: idx_scan_template_tool; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_template_tool ON public.scan_template USING btree (tool_name);


--
-- Name: idx_sgt_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sgt_group ON public.scan_group_templates USING btree (scan_group_id);


--
-- Name: idx_sgt_order; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sgt_order ON public.scan_group_templates USING btree (scan_group_id, execution_order);


--
-- Name: idx_sgt_template; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sgt_template ON public.scan_group_templates USING btree (scan_template_id);


--
-- Name: idx_suite_item_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_suite_item_target ON public.ui_test_suite_item USING btree (target_id);


--
-- Name: idx_ui_test_feature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ui_test_feature ON public.ui_test USING btree (feature);


--
-- Name: idx_ui_test_group_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ui_test_group_name ON public.ui_test USING btree (group_name);


--
-- Name: idx_ui_test_suite_item_suite; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ui_test_suite_item_suite ON public.ui_test_suite_item USING btree (suite_id);


--
-- Name: idx_ui_test_suite_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ui_test_suite_project ON public.ui_test_suite USING btree (project_id);


--
-- Name: idx_user_roles_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_roles_user_id ON public.user_roles USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_enabled; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_enabled ON public.users USING btree (enabled);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: agent_registration trigger_agent_registration_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_agent_registration_timestamp BEFORE UPDATE ON public.agent_registration FOR EACH ROW EXECUTE FUNCTION public.update_agent_timestamp();


--
-- Name: agent_token trigger_agent_token_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_agent_token_timestamp BEFORE UPDATE ON public.agent_token FOR EACH ROW EXECUTE FUNCTION public.update_agent_timestamp();


--
-- Name: custom_script trigger_custom_script_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_custom_script_updated_at BEFORE UPDATE ON public.custom_script FOR EACH ROW EXECUTE FUNCTION public.update_custom_script_updated_at();


--
-- Name: scan_job_item trigger_scan_job_item_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_scan_job_item_timestamp BEFORE UPDATE ON public.scan_job_item FOR EACH ROW EXECUTE FUNCTION public.update_agent_timestamp();


--
-- Name: scan_job trigger_scan_job_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_scan_job_timestamp BEFORE UPDATE ON public.scan_job FOR EACH ROW EXECUTE FUNCTION public.update_agent_timestamp();


--
-- Name: scan_preset trigger_update_scan_preset_timestamp; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_update_scan_preset_timestamp BEFORE UPDATE ON public.scan_preset FOR EACH ROW EXECUTE FUNCTION public.update_scan_preset_timestamp();


--
-- Name: alert_definition alert_definition_scan_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_definition
    ADD CONSTRAINT alert_definition_scan_template_id_fkey FOREIGN KEY (scan_template_id) REFERENCES public.scan_template(id) ON DELETE CASCADE;


--
-- Name: alert_instance alert_instance_alert_definition_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_instance
    ADD CONSTRAINT alert_instance_alert_definition_id_fkey FOREIGN KEY (alert_definition_id) REFERENCES public.alert_definition(id) ON DELETE CASCADE;


--
-- Name: alert_instance alert_instance_scan_comparison_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_instance
    ADD CONSTRAINT alert_instance_scan_comparison_id_fkey FOREIGN KEY (scan_comparison_id) REFERENCES public.scan_comparison(id) ON DELETE SET NULL;


--
-- Name: alert_instance alert_instance_scan_execution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_instance
    ADD CONSTRAINT alert_instance_scan_execution_id_fkey FOREIGN KEY (scan_execution_id) REFERENCES public.scan_execution(id) ON DELETE CASCADE;


--
-- Name: api_scan_history api_scan_history_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history
    ADD CONSTRAINT api_scan_history_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE SET NULL;


--
-- Name: api_scan_history api_scan_history_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history
    ADD CONSTRAINT api_scan_history_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: api_scan_history api_scan_history_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history
    ADD CONSTRAINT api_scan_history_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: api_scan_history api_scan_history_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history
    ADD CONSTRAINT api_scan_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: api_scenario_executions api_scenario_executions_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_executions
    ADD CONSTRAINT api_scenario_executions_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.api_scenarios(id) ON DELETE CASCADE;


--
-- Name: api_scenario_extractions api_scenario_extractions_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_extractions
    ADD CONSTRAINT api_scenario_extractions_step_id_fkey FOREIGN KEY (step_id) REFERENCES public.api_scenario_steps(id) ON DELETE CASCADE;


--
-- Name: api_scenario_step_results api_scenario_step_results_execution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_step_results
    ADD CONSTRAINT api_scenario_step_results_execution_id_fkey FOREIGN KEY (execution_id) REFERENCES public.api_scenario_executions(id) ON DELETE CASCADE;


--
-- Name: api_scenario_step_results api_scenario_step_results_step_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_step_results
    ADD CONSTRAINT api_scenario_step_results_step_id_fkey FOREIGN KEY (step_id) REFERENCES public.api_scenario_steps(id) ON DELETE CASCADE;


--
-- Name: api_scenario_steps api_scenario_steps_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenario_steps
    ADD CONSTRAINT api_scenario_steps_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.api_scenarios(id) ON DELETE CASCADE;


--
-- Name: api_scenarios api_scenarios_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenarios
    ADD CONSTRAINT api_scenarios_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE SET NULL;


--
-- Name: api_scenarios api_scenarios_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenarios
    ADD CONSTRAINT api_scenarios_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: api_scenarios api_scenarios_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenarios
    ADD CONSTRAINT api_scenarios_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: environment_targets environment_services_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environment_targets
    ADD CONSTRAINT environment_services_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;


--
-- Name: environments environments_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments
    ADD CONSTRAINT environments_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: agent_registration fk_agent_current_job; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.agent_registration
    ADD CONSTRAINT fk_agent_current_job FOREIGN KEY (current_job_id) REFERENCES public.scan_job(id) ON DELETE SET NULL;


--
-- Name: api_scan_history fk_api_scan_history_target; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history
    ADD CONSTRAINT fk_api_scan_history_target FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: custom_script fk_custom_script_approved_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_script
    ADD CONSTRAINT fk_custom_script_approved_by FOREIGN KEY (approved_by) REFERENCES public.users(id);


--
-- Name: custom_script fk_custom_script_uploaded_by; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_script
    ADD CONSTRAINT fk_custom_script_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES public.users(id);


--
-- Name: performance_scenarios performance_scenarios_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT performance_scenarios_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE SET NULL;


--
-- Name: performance_scenarios performance_scenarios_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT performance_scenarios_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: performance_scenarios performance_scenarios_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT performance_scenarios_service_id_fkey FOREIGN KEY (service_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: performance_scenarios performance_scenarios_source_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT performance_scenarios_source_scenario_id_fkey FOREIGN KEY (source_scenario_id) REFERENCES public.api_scenarios(id) ON DELETE SET NULL;


--
-- Name: project_applications project_applications_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_applications
    ADD CONSTRAINT project_applications_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: scan_comparison scan_comparison_baseline_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_comparison
    ADD CONSTRAINT scan_comparison_baseline_scan_id_fkey FOREIGN KEY (baseline_scan_id) REFERENCES public.scan_execution(id) ON DELETE CASCADE;


--
-- Name: scan_comparison scan_comparison_current_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_comparison
    ADD CONSTRAINT scan_comparison_current_scan_id_fkey FOREIGN KEY (current_scan_id) REFERENCES public.scan_execution(id) ON DELETE CASCADE;


--
-- Name: scan_execution scan_execution_scan_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_execution
    ADD CONSTRAINT scan_execution_scan_group_id_fkey FOREIGN KEY (scan_group_id) REFERENCES public.scan_group(id) ON DELETE SET NULL;


--
-- Name: scan_execution scan_execution_scan_schedule_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_execution
    ADD CONSTRAINT scan_execution_scan_schedule_id_fkey FOREIGN KEY (scan_schedule_id) REFERENCES public.scan_schedule(id) ON DELETE SET NULL;


--
-- Name: scan_execution scan_execution_scan_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_execution
    ADD CONSTRAINT scan_execution_scan_template_id_fkey FOREIGN KEY (scan_template_id) REFERENCES public.scan_template(id) ON DELETE CASCADE;


--
-- Name: scan_group_templates scan_group_templates_scan_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group_templates
    ADD CONSTRAINT scan_group_templates_scan_group_id_fkey FOREIGN KEY (scan_group_id) REFERENCES public.scan_group(id) ON DELETE CASCADE;


--
-- Name: scan_group_templates scan_group_templates_scan_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_group_templates
    ADD CONSTRAINT scan_group_templates_scan_template_id_fkey FOREIGN KEY (scan_template_id) REFERENCES public.scan_template(id) ON DELETE CASCADE;


--
-- Name: scan_job scan_job_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE SET NULL;


--
-- Name: scan_job_item scan_job_item_scan_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job_item
    ADD CONSTRAINT scan_job_item_scan_job_id_fkey FOREIGN KEY (scan_job_id) REFERENCES public.scan_job(id) ON DELETE CASCADE;


--
-- Name: scan_job_item scan_job_item_scan_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job_item
    ADD CONSTRAINT scan_job_item_scan_template_id_fkey FOREIGN KEY (scan_template_id) REFERENCES public.scan_template(id);


--
-- Name: scan_job scan_job_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: scan_job scan_job_service_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_service_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: scan_job scan_job_ui_test_suite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_ui_test_suite_id_fkey FOREIGN KEY (ui_test_suite_id) REFERENCES public.ui_test_suite(id) ON DELETE SET NULL;


--
-- Name: scan_preset scan_preset_scan_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_preset
    ADD CONSTRAINT scan_preset_scan_template_id_fkey FOREIGN KEY (scan_template_id) REFERENCES public.scan_template(id) ON DELETE CASCADE;


--
-- Name: scan_schedule scan_schedule_scan_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_schedule
    ADD CONSTRAINT scan_schedule_scan_template_id_fkey FOREIGN KEY (scan_template_id) REFERENCES public.scan_template(id) ON DELETE CASCADE;


--
-- Name: ui_test ui_test_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test
    ADD CONSTRAINT ui_test_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: ui_test_suite_item ui_test_suite_item_suite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite_item
    ADD CONSTRAINT ui_test_suite_item_suite_id_fkey FOREIGN KEY (suite_id) REFERENCES public.ui_test_suite(id) ON DELETE CASCADE;


--
-- Name: ui_test_suite_item ui_test_suite_item_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite_item
    ADD CONSTRAINT ui_test_suite_item_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: ui_test_suite_item ui_test_suite_item_ui_test_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite_item
    ADD CONSTRAINT ui_test_suite_item_ui_test_id_fkey FOREIGN KEY (ui_test_id) REFERENCES public.ui_test(id) ON DELETE CASCADE;


--
-- Name: ui_test_suite ui_test_suite_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite
    ADD CONSTRAINT ui_test_suite_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: user_roles user_roles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_roles
    ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict VtHgjKLnNxCO6jtchH2Ru3vf5b2XL9hJZdwvcfRIzBCsNMKDZK6sIWkBnCBTXjq

