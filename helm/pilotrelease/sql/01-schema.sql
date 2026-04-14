--
-- PostgreSQL database dump
--

\restrict 04XhZ9ZqOehvhL0fYEBjefZ2NhgRSoE6jOwqi0e8g6CaPeYlcR8krYSiuyhRlMg

-- Dumped from database version 15.17
-- Dumped by pg_dump version 15.17

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
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


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
-- Name: auth_service_type; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.auth_service_type AS ENUM (
    'NO_AUTH',
    'API_KEY',
    'BEARER_TOKEN',
    'BASIC_AUTH',
    'OAUTH2_CLIENT_CREDENTIALS',
    'OAUTH2_PASSWORD',
    'OAUTH2_AUTHORIZATION_CODE'
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
-- Name: mobile_platform; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.mobile_platform AS ENUM (
    'ANDROID',
    'IOS'
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
    software_version character varying(50),
    capabilities jsonb DEFAULT '[]'::jsonb,
    status character varying(20) DEFAULT 'OFFLINE'::character varying,
    current_job_id bigint,
    last_error text,
    last_seen_at timestamp without time zone,
    registered_at timestamp without time zone DEFAULT now() NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    agent_version character varying(50),
    version bigint DEFAULT 0
);


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
-- Name: api_data_set; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_data_set (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    scenario_id bigint,
    project_id bigint,
    execution_mode character varying(20) DEFAULT 'SEQUENTIAL'::character varying,
    stop_on_failure boolean DEFAULT false,
    source_type character varying(20) DEFAULT 'JSON'::character varying,
    created_by character varying(100),
    updated_by character varying(100),
    version bigint DEFAULT 0,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: api_data_set_entry; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_data_set_entry (
    id bigint NOT NULL,
    data_set_id bigint NOT NULL,
    test_name character varying(255) NOT NULL,
    description text,
    variables jsonb DEFAULT '{}'::jsonb NOT NULL,
    tags character varying(500),
    enabled boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: api_data_set_entry_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_data_set_entry_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_data_set_entry_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_data_set_entry_id_seq OWNED BY public.api_data_set_entry.id;


--
-- Name: api_data_set_entry_result; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_data_set_entry_result (
    id bigint NOT NULL,
    execution_id bigint NOT NULL,
    entry_id bigint,
    scenario_execution_id bigint,
    test_name character varying(255),
    description text,
    status character varying(20) DEFAULT 'PENDING'::character varying,
    duration_ms bigint,
    variables_used jsonb,
    total_steps integer DEFAULT 0,
    passed_steps integer DEFAULT 0,
    failed_steps integer DEFAULT 0,
    error_message text,
    sort_order integer DEFAULT 0,
    started_at timestamp without time zone,
    completed_at timestamp without time zone
);


--
-- Name: api_data_set_entry_result_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_data_set_entry_result_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_data_set_entry_result_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_data_set_entry_result_id_seq OWNED BY public.api_data_set_entry_result.id;


--
-- Name: api_data_set_execution; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.api_data_set_execution (
    id bigint NOT NULL,
    data_set_id bigint NOT NULL,
    scenario_id bigint,
    scenario_name character varying(255),
    status character varying(20) DEFAULT 'PENDING'::character varying,
    execution_mode character varying(20) DEFAULT 'SEQUENTIAL'::character varying,
    total_entries integer DEFAULT 0,
    passed_entries integer DEFAULT 0,
    failed_entries integer DEFAULT 0,
    skipped_entries integer DEFAULT 0,
    triggered_by character varying(100),
    tags character varying(500),
    started_at timestamp without time zone,
    completed_at timestamp without time zone,
    duration_ms bigint,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: api_data_set_execution_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_data_set_execution_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_data_set_execution_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_data_set_execution_id_seq OWNED BY public.api_data_set_execution.id;


--
-- Name: api_data_set_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.api_data_set_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: api_data_set_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.api_data_set_id_seq OWNED BY public.api_data_set.id;


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
    version bigint DEFAULT 0,
    target_id bigint
);


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
    target_id bigint,
    target_name character varying(255),
    base_url_used character varying(500),
    tags jsonb DEFAULT '[]'::jsonb,
    metadata jsonb DEFAULT '{}'::jsonb,
    project_id bigint,
    project_name character varying(255),
    version bigint DEFAULT 0,
    credential_tag character varying(100),
    CONSTRAINT api_scenario_executions_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('RUNNING'::character varying)::text, ('COMPLETED'::character varying)::text, ('FAILED'::character varying)::text, ('CANCELLED'::character varying)::text])))
);


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
    CONSTRAINT api_scenario_extractions_extraction_type_check CHECK (((extraction_type)::text = ANY (ARRAY[('JSONPATH'::character varying)::text, ('REGEX'::character varying)::text, ('HEADER'::character varying)::text])))
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
    CONSTRAINT api_scenario_step_results_status_check CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('RUNNING'::character varying)::text, ('SUCCESS'::character varying)::text, ('FAILED'::character varying)::text, ('SKIPPED'::character varying)::text])))
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
    version bigint DEFAULT 0,
    max_retries integer DEFAULT 0,
    retry_delay_ms bigint DEFAULT 1000,
    retry_backoff_multiplier double precision DEFAULT 2.0,
    retry_on_status_codes jsonb DEFAULT '[]'::jsonb,
    pre_request_hook_type character varying(20),
    pre_request_hook_script text,
    post_request_hook_type character varying(20),
    post_request_hook_script text,
    advanced_assertions jsonb DEFAULT '[]'::jsonb
);


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
    target_id bigint,
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
    version bigint DEFAULT 0,
    data_source_config jsonb DEFAULT '{}'::jsonb,
    data_driven_fail_fast boolean DEFAULT false,
    data_driven_parallelism integer DEFAULT 1,
    app_tag character varying(100),
    application_id bigint
);


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
-- Name: application_deployments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.application_deployments (
    id bigint NOT NULL,
    base_url character varying(500) NOT NULL,
    created_at timestamp without time zone,
    healthcheck_url character varying(500),
    is_active boolean,
    swagger_url character varying(500),
    updated_at timestamp without time zone,
    version bigint,
    application_id bigint NOT NULL,
    environment_id bigint NOT NULL
);


--
-- Name: application_deployments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.application_deployments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: application_deployments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.application_deployments_id_seq OWNED BY public.application_deployments.id;


--
-- Name: applications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.applications (
    id bigint NOT NULL,
    app_tag character varying(100) NOT NULL,
    created_at timestamp without time zone,
    created_by character varying(100),
    description text,
    is_active boolean,
    name character varying(255) NOT NULL,
    updated_at timestamp without time zone,
    updated_by character varying(100),
    version bigint,
    project_id bigint
);


--
-- Name: applications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.applications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: applications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.applications_id_seq OWNED BY public.applications.id;


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
-- Name: auth_services; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.auth_services (
    id bigint NOT NULL,
    environment_id bigint NOT NULL,
    name character varying(100) NOT NULL,
    auth_type character varying(50) NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    is_default boolean DEFAULT false,
    api_key_name character varying(100),
    api_key_location character varying(20),
    auth_url character varying(500),
    token_json_path character varying(200),
    login_body_template text,
    token_expiry_seconds integer,
    refresh_url character varying(500),
    grant_type character varying(50),
    scope character varying(500),
    linked_credential_tags jsonb DEFAULT '[]'::jsonb,
    default_credential_tag character varying(100),
    config jsonb DEFAULT '{}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    version bigint DEFAULT 0
);


--
-- Name: auth_services_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.auth_services_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: auth_services_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.auth_services_id_seq OWNED BY public.auth_services.id;


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
    version bigint DEFAULT 0,
    original_filename character varying(255),
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    script_version character varying(50),
    purpose character varying(20) DEFAULT 'SECURITY'::character varying NOT NULL,
    CONSTRAINT chk_custom_script_category CHECK (((category)::text = ANY (ARRAY[('INFRASTRUCTURE'::character varying)::text, ('APPLICATION'::character varying)::text, ('WEB'::character varying)::text, ('NETWORK'::character varying)::text, ('DATABASE'::character varying)::text, ('PERFORMANCE'::character varying)::text, ('KUBERNETES'::character varying)::text, ('CLOUD'::character varying)::text, ('CUSTOM'::character varying)::text]))),
    CONSTRAINT chk_custom_script_risk_level CHECK (((risk_level)::text = ANY (ARRAY[('LOW'::character varying)::text, ('MEDIUM'::character varying)::text, ('HIGH'::character varying)::text, ('CRITICAL'::character varying)::text]))),
    CONSTRAINT chk_custom_script_status CHECK (((status)::text = ANY (ARRAY[('PENDING'::character varying)::text, ('APPROVED'::character varying)::text, ('REJECTED'::character varying)::text, ('DISABLED'::character varying)::text])))
);


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
-- Name: deployment_credentials; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.deployment_credentials (
    id bigint NOT NULL,
    auth_config jsonb NOT NULL,
    created_at timestamp without time zone,
    created_by character varying(100),
    description text,
    is_active boolean,
    is_default boolean,
    name character varying(255) NOT NULL,
    tag character varying(100) NOT NULL,
    updated_at timestamp without time zone,
    updated_by character varying(100),
    version bigint,
    deployment_id bigint NOT NULL
);


--
-- Name: deployment_credentials_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.deployment_credentials_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deployment_credentials_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.deployment_credentials_id_seq OWNED BY public.deployment_credentials.id;


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
    crawler_config jsonb DEFAULT '{}'::jsonb,
    app_tag character varying(100)
);


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
    version bigint DEFAULT 0,
    variables jsonb DEFAULT '{}'::jsonb
);


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
-- Name: finding; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.finding (
    id bigint NOT NULL,
    scan_job_item_id bigint NOT NULL,
    scan_job_id bigint NOT NULL,
    project_id bigint,
    environment_id bigint,
    target_id bigint,
    scan_id character varying(255),
    type character varying(255),
    title text,
    severity character varying(50),
    description text,
    target character varying(1024),
    evidence text,
    remediation text,
    cwe_id character varying(50),
    cwe_name character varying(255),
    owasp_id character varying(50),
    owasp_name character varying(255),
    cvss_score numeric(4,1),
    cvss_vector character varying(255),
    tool_name character varying(100),
    signature character varying(64) NOT NULL,
    project_name character varying(255),
    environment_name character varying(255),
    target_name character varying(255),
    scan_date timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    version bigint DEFAULT 0
);


--
-- Name: finding_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.finding_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: finding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.finding_id_seq OWNED BY public.finding.id;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


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
-- Name: mobile_apps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mobile_apps (
    id bigint NOT NULL,
    project_id bigint,
    target_id bigint,
    name character varying(255) NOT NULL,
    description text,
    platform character varying(20) NOT NULL,
    app_package character varying(255),
    app_activity character varying(255),
    bundle_id character varying(255),
    app_version character varying(50),
    app_path character varying(500),
    app_size_bytes bigint,
    original_filename character varying(255),
    github_config jsonb,
    appium_capabilities jsonb DEFAULT '{}'::jsonb,
    cloud_provider character varying(50),
    cloud_config jsonb,
    active boolean DEFAULT true,
    version bigint DEFAULT 0,
    created_by character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    inspected_elements jsonb,
    inspection_summary jsonb,
    last_inspected_at timestamp without time zone,
    last_inspection_job_id character varying(100),
    login_config jsonb
);


--
-- Name: mobile_apps_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mobile_apps_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mobile_apps_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mobile_apps_id_seq OWNED BY public.mobile_apps.id;


--
-- Name: mobile_inspection_results; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mobile_inspection_results (
    id bigint NOT NULL,
    job_id uuid,
    mobile_app_id bigint,
    screen_name character varying(255),
    screen_order integer,
    elements jsonb NOT NULL,
    screenshot_path character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    version bigint DEFAULT 0
);


--
-- Name: mobile_inspection_results_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mobile_inspection_results_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mobile_inspection_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mobile_inspection_results_id_seq OWNED BY public.mobile_inspection_results.id;


--
-- Name: mobile_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.mobile_tests (
    id bigint NOT NULL,
    project_id bigint,
    mobile_app_id bigint,
    name character varying(255) NOT NULL,
    description text,
    yaml_content text NOT NULL,
    page_objects text,
    tags character varying(500),
    group_name character varying(100),
    platform character varying(20),
    min_os_version character varying(20),
    status character varying(50) DEFAULT 'ACTIVE'::character varying,
    version bigint DEFAULT 0,
    created_by character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: mobile_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.mobile_tests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mobile_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.mobile_tests_id_seq OWNED BY public.mobile_tests.id;


--
-- Name: performance_scenarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.performance_scenarios (
    id bigint NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    project_id bigint,
    environment_id bigint,
    target_id bigint,
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
    source_scenario_id bigint,
    app_tag character varying(100),
    auth_config jsonb,
    application_id bigint
);


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
-- Name: project_environments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_environments (
    project_id bigint NOT NULL,
    environment_id bigint NOT NULL,
    linked_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    linked_by character varying(100)
);


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
    ui_test_suite_id bigint,
    application_id bigint,
    mobile_test_id bigint,
    execution_group_id character varying(100),
    browser character varying(50)
);


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
    security_domain character varying(30),
    scan_profile character varying(20) DEFAULT 'STANDARD'::character varying,
    estimated_duration_seconds integer,
    cwe_coverage jsonb,
    owasp_coverage jsonb,
    CONSTRAINT chk_scan_template_timeout CHECK (((timeout_seconds IS NULL) OR (timeout_seconds > 0)))
);


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
    version bigint DEFAULT 0,
    group_name character varying(100),
    feature character varying(255),
    tested_version character varying(100),
    auth_config jsonb
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
    version bigint DEFAULT 0
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
-- Name: api_data_set id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set ALTER COLUMN id SET DEFAULT nextval('public.api_data_set_id_seq'::regclass);


--
-- Name: api_data_set_entry id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry ALTER COLUMN id SET DEFAULT nextval('public.api_data_set_entry_id_seq'::regclass);


--
-- Name: api_data_set_entry_result id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry_result ALTER COLUMN id SET DEFAULT nextval('public.api_data_set_entry_result_id_seq'::regclass);


--
-- Name: api_data_set_execution id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_execution ALTER COLUMN id SET DEFAULT nextval('public.api_data_set_execution_id_seq'::regclass);


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
-- Name: application_deployments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_deployments ALTER COLUMN id SET DEFAULT nextval('public.application_deployments_id_seq'::regclass);


--
-- Name: applications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applications ALTER COLUMN id SET DEFAULT nextval('public.applications_id_seq'::regclass);


--
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: auth_services id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_services ALTER COLUMN id SET DEFAULT nextval('public.auth_services_id_seq'::regclass);


--
-- Name: custom_script id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.custom_script ALTER COLUMN id SET DEFAULT nextval('public.custom_script_id_seq'::regclass);


--
-- Name: deployment_credentials id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_credentials ALTER COLUMN id SET DEFAULT nextval('public.deployment_credentials_id_seq'::regclass);


--
-- Name: environment_targets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environment_targets ALTER COLUMN id SET DEFAULT nextval('public.environment_services_id_seq'::regclass);


--
-- Name: environments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environments ALTER COLUMN id SET DEFAULT nextval('public.environments_id_seq'::regclass);


--
-- Name: finding id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finding ALTER COLUMN id SET DEFAULT nextval('public.finding_id_seq'::regclass);


--
-- Name: header_injection_presets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.header_injection_presets ALTER COLUMN id SET DEFAULT nextval('public.header_injection_presets_id_seq'::regclass);


--
-- Name: license id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.license ALTER COLUMN id SET DEFAULT nextval('public.license_id_seq'::regclass);


--
-- Name: mobile_apps id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_apps ALTER COLUMN id SET DEFAULT nextval('public.mobile_apps_id_seq'::regclass);


--
-- Name: mobile_inspection_results id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_inspection_results ALTER COLUMN id SET DEFAULT nextval('public.mobile_inspection_results_id_seq'::regclass);


--
-- Name: mobile_tests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_tests ALTER COLUMN id SET DEFAULT nextval('public.mobile_tests_id_seq'::regclass);


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
-- Name: api_data_set_entry api_data_set_entry_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry
    ADD CONSTRAINT api_data_set_entry_pkey PRIMARY KEY (id);


--
-- Name: api_data_set_entry_result api_data_set_entry_result_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry_result
    ADD CONSTRAINT api_data_set_entry_result_pkey PRIMARY KEY (id);


--
-- Name: api_data_set_execution api_data_set_execution_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_execution
    ADD CONSTRAINT api_data_set_execution_pkey PRIMARY KEY (id);


--
-- Name: api_data_set api_data_set_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set
    ADD CONSTRAINT api_data_set_pkey PRIMARY KEY (id);


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
-- Name: application_deployments application_deployments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_deployments
    ADD CONSTRAINT application_deployments_pkey PRIMARY KEY (id);


--
-- Name: applications applications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT applications_pkey PRIMARY KEY (id);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: auth_services auth_services_environment_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_services
    ADD CONSTRAINT auth_services_environment_name_key UNIQUE (environment_id, name);


--
-- Name: auth_services auth_services_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_services
    ADD CONSTRAINT auth_services_pkey PRIMARY KEY (id);


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
-- Name: deployment_credentials deployment_credentials_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_credentials
    ADD CONSTRAINT deployment_credentials_pkey PRIMARY KEY (id);


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
-- Name: finding finding_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finding
    ADD CONSTRAINT finding_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


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
-- Name: mobile_apps mobile_apps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_apps
    ADD CONSTRAINT mobile_apps_pkey PRIMARY KEY (id);


--
-- Name: mobile_inspection_results mobile_inspection_results_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_inspection_results
    ADD CONSTRAINT mobile_inspection_results_pkey PRIMARY KEY (id);


--
-- Name: mobile_tests mobile_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_tests
    ADD CONSTRAINT mobile_tests_pkey PRIMARY KEY (id);


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
-- Name: project_environments project_environments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_environments
    ADD CONSTRAINT project_environments_pkey PRIMARY KEY (project_id, environment_id);


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
-- Name: applications uk_9j2q5k9u8pytvu2dhd4yhiavx; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT uk_9j2q5k9u8pytvu2dhd4yhiavx UNIQUE (app_tag);


--
-- Name: environment_targets uk_environment_target_name; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environment_targets
    ADD CONSTRAINT uk_environment_target_name UNIQUE (environment_id, name);


--
-- Name: scan_job_item ukap1xahtnbrk08r3bikuaj4mbd; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job_item
    ADD CONSTRAINT ukap1xahtnbrk08r3bikuaj4mbd UNIQUE (scan_job_id, scan_id);


--
-- Name: application_deployments ukav3o735upnoddnlpoyckc46k1; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_deployments
    ADD CONSTRAINT ukav3o735upnoddnlpoyckc46k1 UNIQUE (application_id, environment_id);


--
-- Name: project_applications ukelvuv1ei3akqxfkkj62de8tks; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_applications
    ADD CONSTRAINT ukelvuv1ei3akqxfkkj62de8tks UNIQUE (project_id, name);


--
-- Name: auth_services ukhjwv8p9yeftb4e6o3qjvwbi44; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_services
    ADD CONSTRAINT ukhjwv8p9yeftb4e6o3qjvwbi44 UNIQUE (environment_id, name);


--
-- Name: ui_test_suite_item ukkn9bnjo83nw5nem5vw5tqax8b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ui_test_suite_item
    ADD CONSTRAINT ukkn9bnjo83nw5nem5vw5tqax8b UNIQUE (suite_id, ui_test_id);


--
-- Name: alert_definition uko9r1mlxcrwl6vec9jve5glo9b; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alert_definition
    ADD CONSTRAINT uko9r1mlxcrwl6vec9jve5glo9b UNIQUE (alert_name);


--
-- Name: deployment_credentials ukqkimw1bih39565c6dejdr5wqc; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_credentials
    ADD CONSTRAINT ukqkimw1bih39565c6dejdr5wqc UNIQUE (deployment_id, tag);


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
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


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
-- Name: idx_api_data_set_entry_dataset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_data_set_entry_dataset ON public.api_data_set_entry USING btree (data_set_id);


--
-- Name: idx_api_data_set_entry_result_exec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_data_set_entry_result_exec ON public.api_data_set_entry_result USING btree (execution_id);


--
-- Name: idx_api_data_set_execution_dataset; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_data_set_execution_dataset ON public.api_data_set_execution USING btree (data_set_id);


--
-- Name: idx_api_data_set_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_data_set_project ON public.api_data_set USING btree (project_id);


--
-- Name: idx_api_data_set_scenario; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_data_set_scenario ON public.api_data_set USING btree (scenario_id);


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
-- Name: idx_api_scenario_executions_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_status ON public.api_scenario_executions USING btree (status);


--
-- Name: idx_api_scenario_executions_tags; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_tags ON public.api_scenario_executions USING gin (tags);


--
-- Name: idx_api_scenario_executions_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenario_executions_target ON public.api_scenario_executions USING btree (target_id);


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
-- Name: idx_api_scenarios_app_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_app_tag ON public.api_scenarios USING btree (app_tag);


--
-- Name: idx_api_scenarios_environment; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_environment ON public.api_scenarios USING btree (environment_id);


--
-- Name: idx_api_scenarios_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_project ON public.api_scenarios USING btree (project_id);


--
-- Name: idx_api_scenarios_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_api_scenarios_target ON public.api_scenarios USING btree (target_id);


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
-- Name: idx_custom_script_purpose; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_script_purpose ON public.custom_script USING btree (purpose);


--
-- Name: idx_custom_script_purpose_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_custom_script_purpose_category ON public.custom_script USING btree (purpose, category);


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
-- Name: idx_environment_targets_app_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_environment_targets_app_tag ON public.environment_targets USING btree (app_tag);


--
-- Name: idx_environments_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_environments_active ON public.environments USING btree (is_active);


--
-- Name: idx_environments_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_environments_name ON public.environments USING btree (name);


--
-- Name: idx_finding_environment_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_environment_id ON public.finding USING btree (environment_id);


--
-- Name: idx_finding_project_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_project_id ON public.finding USING btree (project_id);


--
-- Name: idx_finding_project_scan_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_project_scan_date ON public.finding USING btree (project_id, scan_date DESC);


--
-- Name: idx_finding_project_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_project_severity ON public.finding USING btree (project_id, severity);


--
-- Name: idx_finding_project_tool; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_project_tool ON public.finding USING btree (project_id, tool_name);


--
-- Name: idx_finding_scan_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_scan_date ON public.finding USING btree (scan_date DESC);


--
-- Name: idx_finding_scan_job; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_scan_job ON public.finding USING btree (scan_job_id);


--
-- Name: idx_finding_scan_job_item; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_scan_job_item ON public.finding USING btree (scan_job_item_id);


--
-- Name: idx_finding_severity; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_severity ON public.finding USING btree (severity);


--
-- Name: idx_finding_signature; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_signature ON public.finding USING btree (signature);


--
-- Name: idx_finding_target_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_target_id ON public.finding USING btree (target_id);


--
-- Name: idx_finding_tool_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_tool_name ON public.finding USING btree (tool_name);


--
-- Name: idx_finding_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_finding_type ON public.finding USING btree (type);


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
-- Name: idx_mobile_apps_last_inspected; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_apps_last_inspected ON public.mobile_apps USING btree (last_inspected_at) WHERE (last_inspected_at IS NOT NULL);


--
-- Name: idx_mobile_apps_platform; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_apps_platform ON public.mobile_apps USING btree (platform);


--
-- Name: idx_mobile_apps_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_apps_project ON public.mobile_apps USING btree (project_id);


--
-- Name: idx_mobile_apps_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_apps_target ON public.mobile_apps USING btree (target_id);


--
-- Name: idx_mobile_inspection_app; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_inspection_app ON public.mobile_inspection_results USING btree (mobile_app_id);


--
-- Name: idx_mobile_inspection_job; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_inspection_job ON public.mobile_inspection_results USING btree (job_id);


--
-- Name: idx_mobile_tests_app; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_tests_app ON public.mobile_tests USING btree (mobile_app_id);


--
-- Name: idx_mobile_tests_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_mobile_tests_project ON public.mobile_tests USING btree (project_id);


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
-- Name: idx_perf_scenario_source; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_source ON public.performance_scenarios USING btree (source_scenario_id) WHERE (source_scenario_id IS NOT NULL);


--
-- Name: idx_perf_scenario_target; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_perf_scenario_target ON public.performance_scenarios USING btree (target_id);


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
-- Name: idx_project_apps_project; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_apps_project ON public.project_applications USING btree (project_id);


--
-- Name: idx_project_environments_env; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_project_environments_env ON public.project_environments USING btree (environment_id);


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
-- Name: idx_scan_job_application; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_application ON public.scan_job USING btree (application_id);


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
-- Name: idx_scan_job_mobile_test_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scan_job_mobile_test_id ON public.scan_job USING btree (mobile_test_id);


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
-- Name: idx_scenario_executions_credential_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_scenario_executions_credential_tag ON public.api_scenario_executions USING btree (credential_tag) WHERE (credential_tag IS NOT NULL);


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
-- Name: uk_environment_target_baseurl; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uk_environment_target_baseurl ON public.environment_targets USING btree (environment_id, base_url) WHERE (base_url IS NOT NULL);


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
-- Name: api_data_set_entry api_data_set_entry_data_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry
    ADD CONSTRAINT api_data_set_entry_data_set_id_fkey FOREIGN KEY (data_set_id) REFERENCES public.api_data_set(id) ON DELETE CASCADE;


--
-- Name: api_data_set_entry_result api_data_set_entry_result_entry_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry_result
    ADD CONSTRAINT api_data_set_entry_result_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES public.api_data_set_entry(id) ON DELETE SET NULL;


--
-- Name: api_data_set_entry_result api_data_set_entry_result_execution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry_result
    ADD CONSTRAINT api_data_set_entry_result_execution_id_fkey FOREIGN KEY (execution_id) REFERENCES public.api_data_set_execution(id) ON DELETE CASCADE;


--
-- Name: api_data_set_entry_result api_data_set_entry_result_scenario_execution_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_entry_result
    ADD CONSTRAINT api_data_set_entry_result_scenario_execution_id_fkey FOREIGN KEY (scenario_execution_id) REFERENCES public.api_scenario_executions(id) ON DELETE SET NULL;


--
-- Name: api_data_set_execution api_data_set_execution_data_set_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_execution
    ADD CONSTRAINT api_data_set_execution_data_set_id_fkey FOREIGN KEY (data_set_id) REFERENCES public.api_data_set(id) ON DELETE CASCADE;


--
-- Name: api_data_set_execution api_data_set_execution_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set_execution
    ADD CONSTRAINT api_data_set_execution_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.api_scenarios(id);


--
-- Name: api_data_set api_data_set_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set
    ADD CONSTRAINT api_data_set_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: api_data_set api_data_set_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_data_set
    ADD CONSTRAINT api_data_set_scenario_id_fkey FOREIGN KEY (scenario_id) REFERENCES public.api_scenarios(id) ON DELETE SET NULL;


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
-- Name: api_scan_history api_scan_history_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scan_history
    ADD CONSTRAINT api_scan_history_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


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
-- Name: api_scenarios api_scenarios_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenarios
    ADD CONSTRAINT api_scenarios_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: auth_services auth_services_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.auth_services
    ADD CONSTRAINT auth_services_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;


--
-- Name: environment_targets environment_services_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.environment_targets
    ADD CONSTRAINT environment_services_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;


--
-- Name: finding finding_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finding
    ADD CONSTRAINT finding_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE SET NULL;


--
-- Name: finding finding_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finding
    ADD CONSTRAINT finding_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: finding finding_scan_job_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finding
    ADD CONSTRAINT finding_scan_job_id_fkey FOREIGN KEY (scan_job_id) REFERENCES public.scan_job(id) ON DELETE CASCADE;


--
-- Name: finding finding_scan_job_item_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finding
    ADD CONSTRAINT finding_scan_job_item_id_fkey FOREIGN KEY (scan_job_item_id) REFERENCES public.scan_job_item(id) ON DELETE CASCADE;


--
-- Name: finding finding_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.finding
    ADD CONSTRAINT finding_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: application_deployments fk30tkku5nv39ttcm0rjeyr505r; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_deployments
    ADD CONSTRAINT fk30tkku5nv39ttcm0rjeyr505r FOREIGN KEY (environment_id) REFERENCES public.environments(id);


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
-- Name: scan_job fk_scan_job_mobile_test; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT fk_scan_job_mobile_test FOREIGN KEY (mobile_test_id) REFERENCES public.mobile_tests(id) ON DELETE SET NULL;


--
-- Name: deployment_credentials fkb0vyep2b1odtjou6ipwcklcgo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.deployment_credentials
    ADD CONSTRAINT fkb0vyep2b1odtjou6ipwcklcgo FOREIGN KEY (deployment_id) REFERENCES public.application_deployments(id);


--
-- Name: applications fkhm18k2os8y6nqh80nv10g5cb6; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.applications
    ADD CONSTRAINT fkhm18k2os8y6nqh80nv10g5cb6 FOREIGN KEY (project_id) REFERENCES public.projects(id);


--
-- Name: application_deployments fkp7jj1o6nu0uif45mrscd7marg; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.application_deployments
    ADD CONSTRAINT fkp7jj1o6nu0uif45mrscd7marg FOREIGN KEY (application_id) REFERENCES public.applications(id);


--
-- Name: api_scenarios fksa8l0usnpp6dtkv10ca54odjm; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.api_scenarios
    ADD CONSTRAINT fksa8l0usnpp6dtkv10ca54odjm FOREIGN KEY (application_id) REFERENCES public.applications(id);


--
-- Name: performance_scenarios fktrg239lnxftnuvgd2shbayouc; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT fktrg239lnxftnuvgd2shbayouc FOREIGN KEY (application_id) REFERENCES public.applications(id);


--
-- Name: mobile_apps mobile_apps_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_apps
    ADD CONSTRAINT mobile_apps_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


--
-- Name: mobile_apps mobile_apps_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_apps
    ADD CONSTRAINT mobile_apps_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: mobile_inspection_results mobile_inspection_results_mobile_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_inspection_results
    ADD CONSTRAINT mobile_inspection_results_mobile_app_id_fkey FOREIGN KEY (mobile_app_id) REFERENCES public.mobile_apps(id) ON DELETE CASCADE;


--
-- Name: mobile_tests mobile_tests_mobile_app_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_tests
    ADD CONSTRAINT mobile_tests_mobile_app_id_fkey FOREIGN KEY (mobile_app_id) REFERENCES public.mobile_apps(id) ON DELETE SET NULL;


--
-- Name: mobile_tests mobile_tests_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.mobile_tests
    ADD CONSTRAINT mobile_tests_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE SET NULL;


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
-- Name: performance_scenarios performance_scenarios_source_scenario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT performance_scenarios_source_scenario_id_fkey FOREIGN KEY (source_scenario_id) REFERENCES public.api_scenarios(id) ON DELETE SET NULL;


--
-- Name: performance_scenarios performance_scenarios_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.performance_scenarios
    ADD CONSTRAINT performance_scenarios_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


--
-- Name: project_applications project_applications_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_applications
    ADD CONSTRAINT project_applications_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


--
-- Name: project_environments project_environments_environment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_environments
    ADD CONSTRAINT project_environments_environment_id_fkey FOREIGN KEY (environment_id) REFERENCES public.environments(id) ON DELETE CASCADE;


--
-- Name: project_environments project_environments_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_environments
    ADD CONSTRAINT project_environments_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;


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
-- Name: scan_job scan_job_application_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_application_id_fkey FOREIGN KEY (application_id) REFERENCES public.project_applications(id) ON DELETE SET NULL;


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
-- Name: scan_job scan_job_target_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.scan_job
    ADD CONSTRAINT scan_job_target_id_fkey FOREIGN KEY (target_id) REFERENCES public.environment_targets(id) ON DELETE SET NULL;


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

\unrestrict 04XhZ9ZqOehvhL0fYEBjefZ2NhgRSoE6jOwqi0e8g6CaPeYlcR8krYSiuyhRlMg

