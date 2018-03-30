--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

--
-- Name: accepted_state_map(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION accepted_state_map(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, amount integer, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Accepted_state_log"."id", "Accepted"."empl", "Accepted"."dest", "Accepted"."amount", "Accepted_state_log"."rid"
		FROM "Accepted", "Accepted_state_log" 
		WHERE "state"=_state AND "Accepted"."rid"="Accepted_state_log"."rid";
END$$;


ALTER FUNCTION public.accepted_state_map(_state integer) OWNER TO postgres;

--
-- Name: accepted_state_map_until(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION accepted_state_map_until(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, amount integer, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Accepted_state_log"."id", "Accepted"."empl", "Accepted"."dest", "Accepted"."amount", "Accepted_state_log"."rid"
		FROM "Accepted", "Accepted_state_log" 
		WHERE "state"<_state AND "state">1 AND "Accepted"."rid"="Accepted_state_log"."rid";
END$$;


ALTER FUNCTION public.accepted_state_map_until(_state integer) OWNER TO postgres;

--
-- Name: accepted_state_view(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION accepted_state_view(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, amount integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Accepted_state_log"."id", "Accepted"."empl", "Accepted"."dest", "Accepted"."amount"
		FROM "Accepted", "Accepted_state_log" 
		WHERE "state"=_state AND "Accepted"."rid"="Accepted_state_log"."rid"
		ORDER BY "Accepted_state_log"."id" ASC;
END$$;


ALTER FUNCTION public.accepted_state_view(_state integer) OWNER TO postgres;

--
-- Name: adom_integer(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION adom_integer(_state integer) RETURNS TABLE(val integer)
    LANGUAGE plpgsql IMMUTABLE ROWS 1000000
    AS $$BEGIN
	RETURN QUERY 
		SELECT DISTINCT trvlmaxamnt_1."maxAmnt" 
				FROM "TrvlMaxAmnt" AS trvlmaxamnt_1, "TrvlMaxAmnt_state_log" AS trvlmaxamnt_state_log_1
				WHERE trvlmaxamnt_state_log_1."state"="_state"
				AND trvlmaxamnt_1."rid"=trvlmaxamnt_state_log_1."rid"
		UNION
		SELECT DISTINCT trvlcost_1."cost"
				FROM "TrvlCost" AS trvlcost_1, "TrvlCost_state_log" AS trvlcost_state_log_1
				WHERE trvlcost_state_log_1."state"="_state"
				AND trvlcost_1."rid"=trvlcost_state_log_1."rid"
		UNION
		SELECT DISTINCT accepted_1."amount"
				FROM "Accepted" AS accepted_1, "Accepted_state_log" AS accepted_state_log_1
				WHERE accepted_state_log_1."state"="_state" 
				AND accepted_1."rid"=accepted_state_log_1."rid"
		--UNION
		--SELECT "value" FROM "maxamnt_allowed_values"
		ORDER BY 1 ASC;
END$$;


ALTER FUNCTION public.adom_integer(_state integer) OWNER TO postgres;

--
-- Name: adom_string(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION adom_string(_state integer) RETURNS TABLE(val character varying)
    LANGUAGE plpgsql IMMUTABLE ROWS 1000000
    AS $$BEGIN
	RETURN QUERY 
		SELECT DISTINCT pending_1."empl"
				FROM "Pending" AS pending_1, "Pending_state_log" AS pending_state_log_1
				WHERE pending_state_log_1."state"="_state"
				AND pending_1."rid" = pending_state_log_1."rid"
		UNION
		SELECT DISTINCT pending_1."dest"
				FROM "Pending" AS pending_1, "Pending_state_log" AS pending_state_log_1
				WHERE pending_state_log_1."state"="_state"
				AND pending_1."rid" = pending_state_log_1."rid"
		UNION
		SELECT DISTINCT currreq_1."empl"
				FROM "CurrReq" AS currreq_1, "CurrReq_state_log" AS currreq_state_log_1
				WHERE currreq_state_log_1."state"="_state"
				AND currreq_1."rid" = currreq_state_log_1."rid"
		UNION
		SELECT DISTINCT currreq_1."dest"
				FROM "CurrReq" AS currreq_1, "CurrReq_state_log" AS currreq_state_log_1
				WHERE currreq_state_log_1."state"="_state"
				AND currreq_1."rid" = currreq_state_log_1."rid"
		UNION
		SELECT DISTINCT currreq_1."status"
				FROM "CurrReq" AS currreq_1, "CurrReq_state_log" AS currreq_state_log_1
				WHERE currreq_state_log_1."state"="_state"
				AND currreq_1."rid" = currreq_state_log_1."rid"
		ORDER BY 1 ASC;
END$$;


ALTER FUNCTION public.adom_string(_state integer) OWNER TO postgres;

--
-- Name: check_uniqueness(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION check_uniqueness() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
	CASE NEW."id"
		when 1 then null;
		else RAISE EXCEPTION 'You cannot have more than one entry!';
	END CASE;
	RETURN NEW;
END;$$;


ALTER FUNCTION public.check_uniqueness() OWNER TO postgres;

--
-- Name: cleanup(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION cleanup(_statte integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
-- 1. Update the current state counter
	UPDATE "current_state" SET "state"=_state; 

-- 4. Truncate state_log tables
	TRUNCATE "states"; 
	TRUNCATE "Accepted_state_log";
	TRUNCATE "CurrReq_state_log";
	TRUNCATE "Pending_state_log";
	TRUNCATE "TrvlCost_state_log";
	TRUNCATE "TrvlMaxAmnt_state_log";
	TRUNCATE "Rejected_state_log";

-- 5. Remove information about all the possible action bindings
	TRUNCATE rvwreq_params;
	TRUNCATE fillrmb_params;
	TRUNCATE revwreimb_params;
	TRUNCATE startw_params;
	TRUNCATE endw_params;

END;$$;


ALTER FUNCTION public.cleanup(_statte integer) OWNER TO postgres;

--
-- Name: copy_to_update_fillrmb_cost_service(character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION copy_to_update_fillrmb_cost_service(_signature character varying, _value integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	prev_session_id INTEGER;
	curr_session_id INTEGER;
BEGIN
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	"prev_session_id"="curr_session_id"-1;

	INSERT INTO "fillrmb_cost_service" (session_id,service_name,value)
	(SELECT "curr_session_id",
	"fillrmb_cost_service".service_name,
	"_value"
	FROM "fillrmb_cost_service"
	WHERE "fillrmb_cost_service".session_id="prev_session_id"
	AND "fillrmb_cost_service"."service_name"="_signature");
END;$$;


ALTER FUNCTION public.copy_to_update_fillrmb_cost_service(_signature character varying, _value integer) OWNER TO postgres;

--
-- Name: copy_to_update_rvwreq_maxamnt_service(character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION copy_to_update_rvwreq_maxamnt_service(_signature character varying, _value integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	prev_session_id INTEGER;
	curr_session_id INTEGER;
BEGIN
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	"prev_session_id"="curr_session_id"-1;

	INSERT INTO "rvwreq_maxamnt_service" (session_id,service_name,value)
	(SELECT "curr_session_id",
	"rvwreq_maxamnt_service".service_name,
	"_value"
	FROM "rvwreq_maxamnt_service"
	WHERE "rvwreq_maxamnt_service".session_id="prev_session_id"
	AND "rvwreq_maxamnt_service"."service_name"="_signature");
END;$$;


ALTER FUNCTION public.copy_to_update_rvwreq_maxamnt_service(_signature character varying, _value integer) OWNER TO postgres;

--
-- Name: copy_to_update_rvwreq_status_service(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION copy_to_update_rvwreq_status_service(_signature character varying, _value character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	prev_session_id INTEGER;
	curr_session_id INTEGER;
BEGIN
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	"prev_session_id"="curr_session_id"-1;

	INSERT INTO "rvwreq_status_service" (session_id,service_name,value)
	(SELECT "curr_session_id",
	"rvwreq_status_service".service_name,
	"_value"
	FROM "rvwreq_status_service"
	WHERE "rvwreq_status_service".session_id="prev_session_id"
	AND "rvwreq_status_service"."service_name"="_signature");
END;$$;


ALTER FUNCTION public.copy_to_update_rvwreq_status_service(_signature character varying, _value character varying) OWNER TO postgres;

--
-- Name: currreq_state_map(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION currreq_state_map(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, status character varying, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "CurrReq_state_log"."id", "CurrReq"."empl", "CurrReq"."dest", "CurrReq"."status", "CurrReq_state_log"."rid"
		FROM "CurrReq","CurrReq_state_log" 
		WHERE "state"=_state AND "CurrReq"."rid"="CurrReq_state_log"."rid";
END$$;


ALTER FUNCTION public.currreq_state_map(_state integer) OWNER TO postgres;

--
-- Name: currreq_state_map_until(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION currreq_state_map_until(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, status character varying, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "CurrReq_state_log"."id", "CurrReq"."empl", "CurrReq"."dest", "CurrReq"."status", "CurrReq_state_log"."rid"
		FROM "CurrReq","CurrReq_state_log" 
		WHERE "state"<_state AND "state">1 AND "CurrReq"."rid"="CurrReq_state_log"."rid";
END$$;


ALTER FUNCTION public.currreq_state_map_until(_state integer) OWNER TO postgres;

--
-- Name: currreq_state_view(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION currreq_state_view(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, status character varying)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "CurrReq_state_log"."id", "CurrReq"."empl", "CurrReq"."dest", "CurrReq"."status"
		FROM "CurrReq","CurrReq_state_log" 
		WHERE "state"=_state AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		ORDER BY "CurrReq_state_log"."id" ASC;
END$$;


ALTER FUNCTION public.currreq_state_view(_state integer) OWNER TO postgres;

--
-- Name: endw_ca_eval(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION endw_ca_eval(_state integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	IF NOT EXISTS 
	(SELECT "state" FROM "endw_params" WHERE "state"="_state")
	THEN
	INSERT INTO "endw_params" ("state", "empl", "dest", "status", "id_currreq", "checked")
		SELECT 
			"_state", 
			"CurrReq"."empl",
			"CurrReq"."dest",
			"CurrReq"."status",
			"CurrReq_state_log"."id",
			FALSE
		FROM "CurrReq", "CurrReq_state_log"
		WHERE "CurrReq_state_log"."state"=_state 
		AND "CurrReq"."rid"="CurrReq_state_log"."rid" 
		AND "CurrReq"."status" <> 'accepted'
		AND "CurrReq"."status" <> 'complete'
		AND "CurrReq"."status" <> 'submttd';
	END IF;
	-- UPDATE "revwreimb_params" SET "executable"=TRUE;
END$$;


ALTER FUNCTION public.endw_ca_eval(_state integer) OWNER TO postgres;

--
-- Name: endw_eff_eval(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION endw_eff_eval(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_session_id INTEGER;
BEGIN
	UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	-- evaluate effect 1 precondition query
	INSERT INTO "endw_eff_1_eval_res" ("cost","session_id") 
		(
		SELECT "TrvlCost"."cost", "curr_session_id"
		FROM "endw_params", "TrvlCost_state_log", "TrvlCost"
		WHERE "TrvlCost_state_log"."state"=_state
		AND "TrvlCost"."rid"="TrvlCost_state_log"."rid"
		AND "endw_params"."param_id" = "param_rid"
		AND "TrvlCost_state_log"."fid"="endw_params"."id_currreq"
		AND "endw_params"."status" = 'reimbursed');

-- evaluate effect 2 precondition query

	INSERT INTO "endw_eff_2_eval_res" ("exists","session_id") 
		(
		SELECT EXISTS 
		(SELECT 1 
		FROM "endw_params",  "TrvlMaxAmnt_state_log", "TrvlMaxAmnt"
		WHERE "TrvlMaxAmnt_state_log"."state"=_state
		AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid"
		AND "endw_params"."param_id" = "param_rid"
		AND "TrvlMaxAmnt_state_log"."fid"="endw_params"."id_currreq"
		AND "endw_params"."status" = 'rejected'),
		"curr_session_id");

-- evaluate effect 3 precondition query (if a request has been just submitted, we can every time reject it)

--DROP TABLE IF EXISTS "endw_eff_3_eval_res";
	--CREATE TEMPORARY TABLE "endw_eff_3_eval_res" 
		--AS 
		--SELECT EXISTS 
		--(SELECT 1 
		--FROM "endw_params" 
		--WHERE "endw_params"."param_id" = "param_rid" AND
		--"endw_params"."status" = 'submttd');

-- CREATE TEMPORARY TABLE "endw_eff_2_eval_res" AS SELECT "endw_params"."rid","endw_params"."id" FROM "endw_params" WHERE EXISTS (SELECT 1 FROM "trvlmaxamnt_state_map"(_state) AS t1 WHERE t1."rid"="endw_params"."rid") AND "endw_params"."rid" = "param_rid" AND "endw_params"."state" = "_state" AND "endw_params"."status" = 'rejected';
-- no services defined

	 --5. Mark used action parameters as checked
	UPDATE "endw_params" SET "checked"=TRUE 
	WHERE "endw_params"."param_id" = "param_rid"
	AND "endw_params"."state" = "_state";
END$$;


ALTER FUNCTION public.endw_eff_eval(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: endw_eff_exec(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION endw_eff_exec(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_state INTEGER; --current state
	curr_session_id INTEGER;
	hash_Accepted_new UUID;
	hash_Pending_new UUID;
	hash_Rejected_new UUID;
	hash_TrvlCost_new UUID;
	hash_TrvlMaxAmnt_new UUID;
	hash_CurrReq_new UUID;
	collision_state INTEGER;
	collision_Accepted INTEGER := 0;
	collision_Pending INTEGER := 0;
	collision_Rejected INTEGER := 0;
	collision_TrvlCost INTEGER := 0;
	collision_TrvlMaxAmnt INTEGER := 0;
	collision_CurrReq INTEGER := 0;
	TS_flag BOOLEAN;
BEGIN
	SELECT "current_state"."state" FROM "current_state" INTO "curr_state"; --take the current state
	--UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	
	--1. Insert data defined in the ADD list using temporary tables [action]_eff[_i]_eval generated at the effect evaluation stage

	IF EXISTS(SELECT 1 FROM "endw_eff_1_eval_res" WHERE "endw_eff_1_eval_res"."session_id"="curr_session_id")
	THEN
		INSERT INTO "Accepted_endw_dump" ("empl","dest","amount","phash","id","session_id") 
		(SELECT "endw_params"."empl", 
				"endw_params"."dest", 
				"endw_eff_1_eval_res"."cost", 
				md5(row("endw_params"."empl", "endw_params"."dest", "endw_eff_1_eval_res"."cost", "endw_params"."id_currreq")::text)::uuid,
				"endw_params"."id_currreq",
				"curr_session_id"
		FROM "endw_eff_1_eval_res", "endw_params" 
		WHERE "endw_params"."param_id" = "param_rid"
		AND "endw_eff_1_eval_res"."session_id"="curr_session_id");
	END IF;
	-- copy all the rest that has not been affected by ADD (or UPDATE)	
	INSERT INTO "Accepted_endw_state_log_dump" ("session_id","rid","id")
		(SELECT "curr_session_id", "Accepted_state_log"."rid", "Accepted_state_log"."id"
			FROM "Accepted_state_log", "Accepted","endw_params"
			WHERE "Accepted_state_log"."state"=_state
			AND "Accepted"."rid"="Accepted_state_log"."rid"
			AND "endw_params"."param_id" = "param_rid"
			AND "Accepted_state_log"."id"<>"endw_params"."id_currreq");

----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------

	IF (SELECT "endw_eff_2_eval_res"."exists" FROM "endw_eff_2_eval_res" WHERE "endw_eff_2_eval_res"."session_id"="curr_session_id") = true
	THEN
		INSERT INTO "Rejected_endw_dump" ("empl","dest","phash","id","session_id") 
		(SELECT "endw_params"."empl", 
				"endw_params"."dest", 
				md5(row("endw_params"."empl", "endw_params"."dest", "endw_params"."id_currreq")::text)::uuid,
				"endw_params"."id_currreq",
				"curr_session_id"
		FROM "endw_params" 
		WHERE "endw_params"."param_id" = "param_rid"
		--AND "endw_eff_2_eval_res"."exists" = true
		);-- here "exists" is a name of a column automatically generate by PostgreSQL for an EXISTS query (see endw_eff_eval)
	END IF;
	-- copy all the rest that has not been affected by ADD (or UPDATE)
		INSERT INTO "Rejected_endw_state_log_dump" ("session_id","rid","id")
		(SELECT "curr_session_id", "Rejected_state_log"."rid", "Rejected_state_log"."id"
			FROM "Rejected_state_log", "Rejected", "endw_params"
			WHERE "Rejected_state_log"."state"=_state
			AND "Rejected"."rid"="Rejected_state_log"."rid"
			AND "endw_params"."param_id" = "param_rid"
			AND "Rejected_state_log"."id"<>"endw_params"."id_currreq");		
	
----------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------------------------
	-- Given relations appearing the DEL list, "copy" their previous state entries which were not meant to be deleted
		INSERT INTO "TrvlCost_endw_state_log_dump" ("session_id","rid","fid")
		(SELECT "curr_session_id", "TrvlCost_state_log"."rid", "TrvlCost_state_log"."fid"
			FROM "TrvlCost_state_log", "TrvlCost", "endw_params"
			WHERE "TrvlCost_state_log"."state"=_state
			AND "TrvlCost"."rid"="TrvlCost_state_log"."rid"
			AND "endw_params"."param_id" = "param_rid"
			AND "TrvlCost_state_log"."fid"<>"endw_params"."id_currreq");

	-- Given relations appearing the DEL list, "copy" their previous state entries which were not meant to be deleted
		INSERT INTO "TrvlMaxAmnt_endw_state_log_dump" ("session_id","rid","fid")
		(SELECT "curr_session_id", "TrvlMaxAmnt_state_log"."rid", "TrvlMaxAmnt_state_log"."fid"
			FROM "TrvlMaxAmnt_state_log", "TrvlMaxAmnt", "endw_params"
			WHERE "TrvlMaxAmnt_state_log"."state"=_state
			AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid"
			AND "endw_params"."param_id" = "param_rid"
			AND "TrvlMaxAmnt_state_log"."fid"<>"endw_params"."id_currreq");

	-- Given relations appearing in the DEL list, "copy" their previous state entries which were not meant to be deleted
	INSERT INTO "CurrReq_endw_state_log_dump" ("session_id","rid","id")
	(SELECT "curr_session_id", "CurrReq_state_log"."rid", "CurrReq_state_log"."id"
		FROM "CurrReq_state_log", "CurrReq", "endw_params"
		WHERE "CurrReq_state_log"."state"=_state
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "endw_params"."param_id" = "param_rid"
		AND "CurrReq_state_log"."id"<>"endw_params"."id_currreq");




	--3. Calculate state hash for each table, insert it into states (if at least one hash value is unique) and add a new (curr,next) pair to the TS table
	--3.1. Prepare hash values for the untouched data (i.e., we can use the current state)
	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Pending", "Pending_state_log" 
	WHERE "state"=_state 
	AND "Pending"."rid"="Pending_state_log"."rid" 
	ORDER BY "Pending_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_pending_new;

	
	--generate hashes for the relations that have been only temporally affected
	SELECT md5(ARRAY(SELECT "phash" 
	FROM "CurrReq", "CurrReq_endw_state_log_dump" 
	WHERE "CurrReq"."rid"="CurrReq_endw_state_log_dump"."rid" 
	AND "CurrReq_endw_state_log_dump"."session_id"="curr_session_id"  
	ORDER BY "CurrReq_endw_state_log_dump"."id" ASC)::TEXT)::uuid INTO hash_currreq_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlCost", "TrvlCost_endw_state_log_dump" 
	WHERE "TrvlCost"."rid"="TrvlCost_endw_state_log_dump"."rid" 
	AND "TrvlCost_endw_state_log_dump"."session_id"="curr_session_id" 
	ORDER BY "TrvlCost_endw_state_log_dump" ."fid" ASC)::TEXT)::uuid INTO hash_trvlcost_new;


	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlMaxAmnt", "TrvlMaxAmnt_endw_state_log_dump" 
	WHERE "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_endw_state_log_dump"."rid" 
	AND "TrvlMaxAmnt_endw_state_log_dump"."session_id"="curr_session_id" 
	ORDER BY "TrvlMaxAmnt_endw_state_log_dump"."fid" ASC)::TEXT)::uuid INTO hash_trvlmaxamnt_new;

	-- creat "empty" stub hash values (in case of NULL results)
	/*SELECT '99914b93-2bd3-7a50-b983-c5e7c90ae93b' INTO hash_accepted_new;
	SELECT '99914b93-2bd3-7a50-b983-c5e7c90ae93b' INTO hash_rejected_new;*/



	--generate hashes in a special way only for those relations which have been also non-temporally updated
	--IF EXISTS(SELECT 1 FROM "Accepted_endw_dump" WHERE "Accepted_endw_dump"."session_id" = "curr_session_id")
	--THEN
	SELECT 
		md5(ARRAY( 
				SELECT res.phash FROM 
				(SELECT "Accepted_endw_dump"."id", "Accepted_endw_dump"."phash" --take hash of entries in tmp table
					FROM "Accepted_endw_dump" 
					WHERE "Accepted_endw_dump"."session_id" = "curr_session_id" 
				UNION
				SELECT "Accepted"."id", "Accepted"."phash" --take hash of entries in the original table using tmp temporal portrait (only copied historical values)
					FROM "Accepted", "Accepted_endw_state_log_dump" 
					WHERE "Accepted"."rid"="Accepted_endw_state_log_dump"."rid" 
					AND "Accepted_endw_state_log_dump"."session_id"="curr_session_id" 
				ORDER BY "id" ASC) AS res)::TEXT)::uuid
	INTO hash_accepted_new;
	--END IF;

	--generate hashes in a special way only for those relations which have been also non-temporally updated
	--IF EXISTS(SELECT 1 FROM "Rejected_endw_dump" WHERE "Rejected_endw_dump"."session_id" = "curr_session_id")
	--THEN
		SELECT 
		md5(ARRAY(
				SELECT res.phash FROM 
				(SELECT "Rejected_endw_dump"."id", "Rejected_endw_dump"."phash" --take hash of entries in tmp table
					FROM "Rejected_endw_dump" 
					WHERE "Rejected_endw_dump"."session_id" = "curr_session_id" 
				UNION
				SELECT "Rejected"."id", "Rejected"."phash" --take hash of entries in the original table using tmp temporal portrait (only copied historical values)
					FROM "Rejected", "Rejected_endw_state_log_dump" 
					WHERE "Rejected"."rid"="Rejected_endw_state_log_dump"."rid" 
					AND "Rejected_endw_state_log_dump"."session_id"="curr_session_id" 
				ORDER BY "id" ASC) AS res)::TEXT)::uuid
		INTO hash_rejected_new;
	--END IF; 


	--3.2. Check if a tuple compiled out of new hash values can have collisions by conferming that there are no states with exactly the same hashe values
	SELECT COALESCE(MAX(state),0) FROM "states" 
	WHERE "hash_Accepted"=hash_accepted_new
	AND "hash_Pending"=hash_pending_new
	AND "hash_Rejected"=hash_rejected_new
	AND "hash_TrvlCost"=hash_trvlcost_new
	AND "hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "hash_CurrReq"=hash_currreq_new
	INTO "collision_state"; --assume that the first state has a value 1

	-- just for debugging 
	UPDATE states_metadata SET collisions_count=
	collisions_count +
	(SELECT COALESCE(COUNT("state"),0) FROM "states" 
	WHERE "states"."hash_Accepted"=hash_accepted_new
	AND "states"."hash_Pending"=hash_pending_new
	AND "states"."hash_Rejected"=hash_rejected_new
	AND "states"."hash_TrvlCost"=hash_trvlcost_new
	AND "states"."hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "states"."hash_CurrReq"=hash_currreq_new);


	-- just for debugging
	IF "collision_state"<>0 THEN
		SELECT COUNT(1) FROM (
		SELECT * FROM accepted_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM accepted_state_view("collision_state") AS t2) AS res INTO collision_Accepted;

		SELECT COUNT(1) FROM (
		SELECT * FROM pending_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM pending_state_view("collision_state") AS t2) AS res INTO collision_Pending;

		SELECT COUNT(1) FROM (
		SELECT * FROM rejected_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM rejected_state_view("collision_state") AS t2) AS res INTO collision_Rejected;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlcost_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlcost_state_view("collision_state") AS t2) AS res INTO collision_TrvlCost;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlmaxamnt_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlmaxamnt_state_view("collision_state") AS t2) AS res INTO collision_TrvlMaxAmnt;

		SELECT COUNT(1) FROM (
		SELECT * FROM currreq_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM currreq_state_view("collision_state") AS t2) AS res INTO collision_CurrReq;

		-- just for debugging
		IF (collision_CurrReq + 
			collision_TrvlMaxAmnt + 
			collision_TrvlCost + 
			collision_Rejected + 
			collision_Pending + 
			collision_Accepted=0) THEN
			"collision_state":=0;
			UPDATE states_metadata SET deepcheck_success=deepcheck_success+1;
		END IF;
	END IF;

	--3.3. If a state has not been generated yet (i.e., collision_state=0), add it to the states table 
	IF "collision_state"=0 THEN

		-- insert all the data from the temporary tables into original tables
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state + 1, "rid", "id"
		FROM "CurrReq_endw_state_log_dump"
		WHERE "CurrReq_endw_state_log_dump"."session_id"="curr_session_id");

		INSERT INTO "TrvlCost_state_log" ("state", "rid", "fid")
		(SELECT curr_state + 1, "rid", "fid"
		FROM "TrvlCost_endw_state_log_dump"
		WHERE "TrvlCost_endw_state_log_dump"."session_id"="curr_session_id");

		INSERT INTO "TrvlMaxAmnt_state_log" ("state", "rid", "fid")
		(SELECT curr_state + 1, "rid", "fid"
		FROM "TrvlMaxAmnt_endw_state_log_dump"
		WHERE "TrvlMaxAmnt_endw_state_log_dump"."session_id"="curr_session_id");
		

		-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "Accepted"("empl", "dest", "amount", "id", "rid", "phash")
		(SELECT "empl", "dest", "amount", "id", "rid", "phash" FROM "Accepted_endw_dump" 
		WHERE "Accepted_endw_dump"."session_id"="curr_session_id"
		AND NOT EXISTS 
		(SELECT 1 FROM "Accepted" WHERE "Accepted"."phash"="Accepted_endw_dump"."phash"));

		-- now, for each NEW added data create a corresponding entry in the temporal portrait of CurrReq (i.e., CurrReq_state_log)
		INSERT INTO "Accepted_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "Accepted"."rid", "Accepted"."id" FROM "Accepted","Accepted_endw_dump"
		WHERE "Accepted"."phash"="Accepted_endw_dump"."phash"
		AND "Accepted_endw_dump"."session_id"="curr_session_id"
		--AND "Accepted"."rid"="Accepted_endw_dump"."rid"
		);
	
		-- now, copy all the data of Accepted that has not been changed (i.e., the one we put in CurrReq_state_log_tmp)
		INSERT INTO "Accepted_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "Accepted"."rid", "Accepted"."id" FROM "Accepted", "Accepted_endw_state_log_dump"
		WHERE "Accepted_endw_state_log_dump"."session_id"="curr_session_id"
		AND "Accepted"."rid"="Accepted_endw_state_log_dump"."rid");
	
		-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "Rejected"("empl", "dest", "id", "rid", "phash") 
		(SELECT "empl", "dest", "id", "rid", "phash" FROM "Rejected_endw_dump" 
		WHERE "Rejected_endw_dump"."session_id" = "curr_session_id"
		AND NOT EXISTS 
		(SELECT 1 FROM "Rejected" WHERE "Rejected"."phash"="Rejected_endw_dump"."phash"));
			
		-- now, for each NEW added data create a corresponding entry in the temporal portrait of Rejected (i.e., Rejected_state_log)
		INSERT INTO "Rejected_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "Rejected"."rid", "Rejected"."id" FROM "Rejected","Rejected_endw_dump"
		WHERE "Rejected"."phash"="Rejected_endw_dump"."phash"
		AND "Rejected_endw_dump"."session_id" = "curr_session_id"
		--AND "Rejected"."rid" = "Rejected_endw_dump"."rid"
		);
	
		-- now, copy all the data of Rejected that has not been changed (i.e., the one we put in Rejected_state_log_tmp)
		INSERT INTO "Rejected_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "Rejected"."rid", "Rejected"."id" FROM "Rejected", "Rejected_endw_state_log_dump"
		WHERE "Rejected_endw_state_log_dump"."session_id" = "curr_session_id"
		AND "Rejected"."rid"="Rejected_endw_state_log_dump"."rid");
	

		--2. "Duplicate" data from the tables that are not in the DEL and ADD lists

		INSERT INTO "Pending_state_log" ("state","rid","id") 
		(SELECT "curr_state"+1,"rid","id" 
		FROM "Pending_state_log" 
		WHERE "state"="_state");
	

		INSERT INTO "states" select 
			"curr_state"+1, 
			hash_accepted_new,
			hash_pending_new,
			hash_rejected_new,
			hash_trvlcost_new,
			hash_trvlmaxamnt_new,
			hash_currreq_new; --add the state to the table of states
		UPDATE "current_state" SET "state"="state"+1; --increment the global state counter
	END IF;

	--4. If TS generation is enabled, add an edge given state analysis
	SELECT "enabled" FROM "TS_enabled" INTO ts_flag;
	IF "ts_flag" = TRUE THEN
		--4.a. collision state coinsides with a state that has been already created before (including loops)
		IF "collision_state"!="_state" and "collision_state">0 THEN
			-- just for debugging 
			UPDATE states_metadata SET recycled_states=recycled_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES ("_state","collision_state",'endw',param_rid);
		END IF;
		--4.b. this state has not been generated yet
		IF "collision_state"=0 THEN
			-- just for debugging 
			UPDATE states_metadata SET unique_states=unique_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES (_state,curr_state+1,'endw',param_rid); --insert a transition
		END IF;
	END IF;

END;$$;


ALTER FUNCTION public.endw_eff_exec(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: fillrmb_ca_eval(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fillrmb_ca_eval(_state integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	IF NOT EXISTS 
	(SELECT "state" FROM "fillrmb_params" WHERE "state"="_state")
	THEN
	INSERT INTO "fillrmb_params" ("state", "empl", "dest", "id_currreq", "checked")
		(
		SELECT 
			"_state", 
			"CurrReq"."empl",
			"CurrReq"."dest",
			"CurrReq_state_log"."id",
			FALSE
		FROM "CurrReq", "CurrReq_state_log"
		WHERE "CurrReq_state_log"."state"=_state 
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "status"='accepted'
		);
	END IF;
END$$;


ALTER FUNCTION public.fillrmb_ca_eval(_state integer) OWNER TO postgres;

--
-- Name: fillrmb_eff_eval(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fillrmb_eff_eval(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_session_id INTEGER;
BEGIN
	UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	
	INSERT INTO fillrmb_cost_service ("session_id","service_name","value")
		(
			SELECT 
			"curr_session_id",
			'cost('||"fillrmb_params"."empl"||','||"fillrmb_params"."dest"||')',
			NULL
			FROM "fillrmb_params"
			WHERE "fillrmb_params"."param_id"="param_rid"
		);

 --5. Mark used action parameters as checked
	UPDATE "fillrmb_params" SET "checked"=TRUE 
	WHERE "fillrmb_params"."param_id" = "param_rid"
	AND "fillrmb_params"."state" = "_state";
END$$;


ALTER FUNCTION public.fillrmb_eff_eval(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: fillrmb_eff_exec(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION fillrmb_eff_exec(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_state INTEGER; --current state	
	curr_session_id INTEGER;
	hash_accepted_new UUID;
	hash_pending_new UUID;
	hash_rejected_new UUID;
	hash_trvlcost_new UUID;
	hash_trvlmaxamnt_new UUID;
	hash_currreq_new UUID;
	collision_state INTEGER;
	collision_Accepted INTEGER := 0;
	collision_Pending INTEGER := 0;
	collision_Rejected INTEGER := 0;
	collision_TrvlCost INTEGER := 0;
	collision_TrvlMaxAmnt INTEGER := 0;
	collision_CurrReq INTEGER := 0;
	TS_flag BOOLEAN;
BEGIN
	SELECT "current_state"."state" FROM "current_state" INTO "curr_state"; --take the current state
	--UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	--1. Insert data defined in the ADD list using temporary tables [action]_eff[_i]_eval generated at the effect evaluation stage

	
	INSERT INTO "TrvlCost_fillrmb_dump" ("cost", "phash", "fid", "session_id")
	(SELECT "fillrmb_cost_service"."value", 
			md5(row("fillrmb_cost_service"."value", "fillrmb_params"."id_currreq")::TEXT)::uuid,
			"fillrmb_params"."id_currreq",
			"curr_session_id"
	FROM "fillrmb_params", "fillrmb_cost_service"
	WHERE "fillrmb_cost_service"."service_name"= 'cost('||"fillrmb_params"."empl"||','||"fillrmb_params"."dest"||')'
	AND "fillrmb_params"."param_id"="param_rid"
	AND "fillrmb_cost_service"."session_id"="curr_session_id");
	
	-- copy all the rest that has not been affected by ADD (or UPDATE)
	
	INSERT INTO "TrvlCost_fillrmb_state_log_dump" ("session_id","rid","fid")
	(SELECT "curr_session_id", "TrvlCost_state_log"."rid", "TrvlCost_state_log"."fid"
		FROM "TrvlCost_state_log", "TrvlCost", "fillrmb_params"
		WHERE "TrvlCost_state_log"."state"=_state
		AND "TrvlCost"."rid"="TrvlCost_state_log"."rid"
		AND "fillrmb_params"."param_id" = "param_rid"
		AND "TrvlCost_state_log"."fid"<>"fillrmb_params"."id_currreq");


	INSERT INTO "CurrReq_fillrmb_dump" ("empl", "dest", "status", "phash", "id", "session_id" )
	(SELECT "fillrmb_params"."empl", 
			"fillrmb_params"."dest", 
			'complete',
			md5(row("fillrmb_params"."empl", "fillrmb_params"."dest", 'complete', "fillrmb_params"."id_currreq")::TEXT)::uuid,
			"fillrmb_params"."id_currreq",
			"curr_session_id"
	FROM "fillrmb_params"
	WHERE "fillrmb_params"."param_id"="param_rid");

	-- copy all the rest that has not been affected by ADD (or UPDATE)
	INSERT INTO "CurrReq_fillrmb_state_log_dump" ("session_id","rid","id")
	(SELECT "curr_session_id", "CurrReq_state_log"."rid", "CurrReq_state_log"."id"
		FROM "CurrReq_state_log","CurrReq", "fillrmb_params"
		WHERE "CurrReq_state_log"."state"=_state
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "fillrmb_params"."param_id" = "param_rid"
		AND "CurrReq_state_log"."id"<>"fillrmb_params"."id_currreq");



	--3. Calculate state hash for each table, insert it into states (if at least one hash value is unique) and add a new (curr,next) pair to the TS table
	--3.1. Prepare hash values for the untouched data (i.e., we can use the current state)


	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Pending", "Pending_state_log" 
	WHERE "state"=_state 
	AND "Pending"."rid"="Pending_state_log"."rid" 
	ORDER BY "Pending_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_pending_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Accepted", "Accepted_state_log" 
	WHERE "state"=_state 
	AND "Accepted"."rid"="Accepted_state_log"."rid" 
	ORDER BY "Accepted_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_accepted_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Rejected", "Rejected_state_log" 
	WHERE "state"=_state 
	AND "Rejected"."rid"="Rejected_state_log"."rid" 
	ORDER BY "Rejected_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_rejected_new;


	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log" 
	WHERE "state"=_state 
	AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" 
	ORDER BY "TrvlMaxAmnt_state_log"."fid" ASC)::TEXT)::uuid 
	INTO hash_trvlmaxamnt_new;


	SELECT 
		md5(ARRAY(
				SELECT res.phash FROM 
				(SELECT "CurrReq_fillrmb_dump"."id", "CurrReq_fillrmb_dump"."phash" --take hash of entries in tmp table
					FROM "CurrReq_fillrmb_dump" 
					WHERE "CurrReq_fillrmb_dump"."session_id"="curr_session_id"
				UNION
				SELECT "CurrReq"."id", "CurrReq"."phash" --take hash of entries in the original table using tmp temporal portrait (only copied historical values)
					FROM "CurrReq", "CurrReq_fillrmb_state_log_dump" 
					WHERE "CurrReq"."rid"="CurrReq_fillrmb_state_log_dump"."rid" 
					AND "CurrReq_fillrmb_state_log_dump"."session_id" = "curr_session_id" 
				ORDER BY id ASC) AS res)::TEXT)::uuid
	INTO hash_currreq_new;


	SELECT 
		md5(ARRAY(
				SELECT res.phash FROM 
				(SELECT "TrvlCost_fillrmb_dump"."fid", "TrvlCost_fillrmb_dump"."phash" --take hash of entries in the temporary table
					FROM "TrvlCost_fillrmb_dump" 
					WHERE "TrvlCost_fillrmb_dump"."session_id" = "curr_session_id" 
				UNION
				SELECT "TrvlCost"."fid", "TrvlCost"."phash" --take hash of entries in the original table using a corresponding temporary temporal portrait (only copied historical values)
					FROM "TrvlCost", "TrvlCost_fillrmb_state_log_dump" 
					WHERE "TrvlCost"."rid"="TrvlCost_fillrmb_state_log_dump"."rid" 
					AND "TrvlCost_fillrmb_state_log_dump"."session_id" = "curr_session_id" 
				ORDER BY fid ASC) AS res)::TEXT)::uuid
	INTO hash_trvlcost_new;


	--3.2. Check if a tuple compiled out of new hash values can have collisions by conferming that there are no states with exactly the same hashe values
	SELECT COALESCE(MAX(state),0) FROM "states" 
	WHERE "hash_Accepted"=hash_accepted_new
	AND "hash_Pending"=hash_pending_new
	AND "hash_Rejected"=hash_rejected_new
	AND "hash_TrvlCost"=hash_trvlcost_new
	AND "hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "hash_CurrReq"=hash_currreq_new
	INTO "collision_state"; --assume that the first state has a value 1

	-- just for debugging 
	UPDATE states_metadata SET collisions_count=
	collisions_count +
	(SELECT COALESCE(COUNT("state"),0) FROM "states" 
	WHERE "states"."hash_Accepted"=hash_accepted_new
	AND "states"."hash_Pending"=hash_pending_new
	AND "states"."hash_Rejected"=hash_rejected_new
	AND "states"."hash_TrvlCost"=hash_trvlcost_new
	AND "states"."hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "states"."hash_CurrReq"=hash_currreq_new);

	
	-- just for debugging
	IF "collision_state"<>0 THEN
		SELECT COUNT(1) FROM (
		SELECT * FROM accepted_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM accepted_state_view("collision_state") AS t2) AS res INTO collision_Accepted;

		SELECT COUNT(1) FROM (
		SELECT * FROM pending_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM pending_state_view("collision_state") AS t2) AS res INTO collision_Pending;

		SELECT COUNT(1) FROM (
		SELECT * FROM rejected_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM rejected_state_view("collision_state") AS t2) AS res INTO collision_Rejected;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlcost_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlcost_state_view("collision_state") AS t2) AS res INTO collision_TrvlCost;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlmaxamnt_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlmaxamnt_state_view("collision_state") AS t2) AS res INTO collision_TrvlMaxAmnt;

		SELECT COUNT(1) FROM (
		SELECT * FROM currreq_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM currreq_state_view("collision_state") AS t2) AS res INTO collision_CurrReq;

		-- just for debugging
		IF (collision_CurrReq + 
			collision_TrvlMaxAmnt + 
			collision_TrvlCost + 
			collision_Rejected + 
			collision_Pending + 
			collision_Accepted=0) THEN
			"collision_state":=0;
			UPDATE states_metadata SET deepcheck_success=deepcheck_success+1;
		END IF;
	END IF;


	--3.3. If a state has not been generated yet (i.e., collision_state=0), add it to the states table 
	IF "collision_state"=0 THEN

		-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "CurrReq"("empl", "dest", "status", "id", "rid", "phash") 
		(SELECT "empl", "dest", "status", "id", "rid", "phash" FROM "CurrReq_fillrmb_dump" 
			WHERE "CurrReq_fillrmb_dump"."session_id" = "curr_session_id"
			AND NOT EXISTS 
			(SELECT 1 FROM "CurrReq" 
			WHERE "CurrReq"."phash"="CurrReq_fillrmb_dump"."phash"));

		-- now, for each NEW added data create a corresponding entry in the temporal portrait of CurrReq (i.e., CurrReq_state_log)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM "CurrReq","CurrReq_fillrmb_dump" 
		WHERE "CurrReq"."phash"="CurrReq_fillrmb_dump"."phash"
		AND "CurrReq_fillrmb_dump"."session_id" = "curr_session_id"
		--AND "CurrReq"."rid"="CurrReq_fillrmb_dump"."rid"
		);

		-- now, copy all the data of CurrReq that has not been changed (i.e., the one we put in CurrReq_state_log_tmp)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM  "CurrReq_fillrmb_state_log_dump","CurrReq"
			WHERE "CurrReq_fillrmb_state_log_dump"."session_id" = "curr_session_id"
			AND "CurrReq"."rid"="CurrReq_fillrmb_state_log_dump"."rid");


		-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "TrvlCost"("cost","fid","rid","phash") 
		(SELECT "cost","fid","rid","phash" FROM "TrvlCost_fillrmb_dump" 
			WHERE "TrvlCost_fillrmb_dump"."session_id" = "curr_session_id" 
			AND NOT EXISTS 
			(SELECT 1 FROM "TrvlCost" 
			WHERE "TrvlCost"."phash"="TrvlCost_fillrmb_dump"."phash"));

		-- now, for each NEW added data create a corresponding entry in the temporal portrait of CurrReq (i.e., CurrReq_state_log)
		INSERT INTO "TrvlCost_state_log" ("state", "rid", "fid")
		(SELECT curr_state+1, "TrvlCost"."rid", "TrvlCost"."fid" FROM "TrvlCost","TrvlCost_fillrmb_dump"
		WHERE "TrvlCost"."phash"="TrvlCost_fillrmb_dump"."phash"
		AND "TrvlCost_fillrmb_dump"."session_id"= "curr_session_id"
		--AND "TrvlCost"."rid"="TrvlCost_fillrmb_dump"."rid"
		);

		-- now, copy all the data of CurrReq that has not been changed (i.e., the one we put in CurrReq_state_log_tmp)
		INSERT INTO "TrvlCost_state_log" ("state", "rid", "fid")
		(SELECT curr_state+1, "TrvlCost"."rid", "TrvlCost"."fid" FROM  "TrvlCost_fillrmb_state_log_dump","TrvlCost"
			WHERE "TrvlCost_fillrmb_state_log_dump"."session_id" = "curr_session_id"
			AND "TrvlCost"."rid"="TrvlCost_fillrmb_state_log_dump"."rid");

		

	--2. "Duplicate" data from the tables that are not in the DEL and ADD lists
	
		INSERT INTO "Accepted_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Accepted_state_log" WHERE "state"="_state");
		INSERT INTO "Pending_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Pending_state_log" WHERE "state"="_state");
		INSERT INTO "Rejected_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Rejected_state_log" WHERE "state"="_state");
		INSERT INTO "TrvlMaxAmnt_state_log" ("state","rid","fid") (SELECT "curr_state"+1,"rid","fid" FROM "TrvlMaxAmnt_state_log" WHERE "state"="_state");
		--INSERT INTO "CurrReq_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "CurrReq_state_log" WHERE "state"="_state");

		--create a new state
		INSERT INTO "states" select 
			"curr_state"+1, 
			hash_accepted_new,
			hash_pending_new,
			hash_rejected_new,
			hash_trvlcost_new,
			hash_trvlmaxamnt_new,
			hash_currreq_new; --add the state to the table of states
		UPDATE "current_state" SET "state"="state"+1; --increment the global state counter


	END IF;

	--4. If TS generation is enabled, add an edge given state analysis
	SELECT "enabled" FROM "TS_enabled" INTO ts_flag;
	IF "ts_flag" = TRUE THEN
		--4.a. collision state coinsides with a state that has been already created before (including loops)
		IF "collision_state"!="_state" and "collision_state">0 THEN
			-- just for debugging 
			UPDATE states_metadata SET recycled_states=recycled_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES ("_state","collision_state",'fillrmb',param_rid);
		END IF;
		--4.b. this state has not been generated yet
		IF "collision_state"=0 THEN
			-- just for debugging 
			UPDATE states_metadata SET unique_states=unique_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES (_state,curr_state+1,'fillrmb',param_rid); --insert a transition
		END IF;
	END IF;

	
END;$$;


ALTER FUNCTION public.fillrmb_eff_exec(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: hash_accepted(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION hash_accepted(_state integer) RETURNS uuid
    LANGUAGE plpgsql
    AS $$BEGIN
	RETURN md5(ARRAY(SELECT "phash" FROM "Accepted", "Accepted_state_log" 
	WHERE "state"=_state AND "Accepted"."rid"="Accepted_state_log"."rid" ORDER BY "Accepted_state_log"."id" ASC)::TEXT)::UUID;
END;$$;


ALTER FUNCTION public.hash_accepted(_state integer) OWNER TO postgres;

--
-- Name: hash_currreq(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION hash_currreq(_state integer) RETURNS uuid
    LANGUAGE plpgsql
    AS $$BEGIN
	RETURN md5(ARRAY(SELECT "phash" FROM "CurrReq", "CurrReq_state_log" 
	WHERE "state"=_state AND "CurrReq"."rid"="CurrReq_state_log"."rid" ORDER BY "CurrReq_state_log"."id" ASC)::TEXT)::UUID;
END;$$;


ALTER FUNCTION public.hash_currreq(_state integer) OWNER TO postgres;

--
-- Name: hash_pending(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION hash_pending(_state integer) RETURNS uuid
    LANGUAGE plpgsql
    AS $$BEGIN
	RETURN md5(ARRAY(SELECT "phash" FROM "Pending", "Pending_state_log" 
	WHERE "state"=_state AND "Pending"."rid"="Pending_state_log"."rid" ORDER BY "Pending_state_log"."id" ASC)::TEXT)::UUID;
END;$$;


ALTER FUNCTION public.hash_pending(_state integer) OWNER TO postgres;

--
-- Name: hash_rejected(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION hash_rejected(_state integer) RETURNS uuid
    LANGUAGE plpgsql
    AS $$BEGIN
	RETURN md5(ARRAY(SELECT "phash" FROM "Rejected", "Rejected_state_log" 
	WHERE "state"=_state AND "Rejected"."rid"="Rejected_state_log"."rid" ORDER BY "Rejected_state_log"."id" ASC)::TEXT)::uuid;
END;$$;


ALTER FUNCTION public.hash_rejected(_state integer) OWNER TO postgres;

--
-- Name: hash_trvlcost(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION hash_trvlcost(_state integer) RETURNS uuid
    LANGUAGE plpgsql
    AS $$BEGIN
	RETURN md5(ARRAY(SELECT "phash" FROM "TrvlCost", "TrvlCost_state_log" 
	WHERE "state"=_state AND "TrvlCost"."rid"="TrvlCost_state_log"."rid" ORDER BY "TrvlCost_state_log"."fid" ASC)::TEXT)::UUID;
END;$$;


ALTER FUNCTION public.hash_trvlcost(_state integer) OWNER TO postgres;

--
-- Name: hash_trvlmaxamnt(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION hash_trvlmaxamnt(_state integer) RETURNS uuid
    LANGUAGE plpgsql
    AS $$BEGIN
	RETURN md5(ARRAY(SELECT "phash" FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log" 
	WHERE "state"=_state AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" ORDER BY "TrvlMaxAmnt_state_log"."fid" ASC)::TEXT)::UUID;
END;$$;


ALTER FUNCTION public.hash_trvlmaxamnt(_state integer) OWNER TO postgres;

--
-- Name: increment_current_session_id(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION increment_current_session_id() RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
END;$$;


ALTER FUNCTION public.increment_current_session_id() OWNER TO postgres;

--
-- Name: initialize(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION initialize() RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN

	-- 1. Null the curretn state counter
	UPDATE "current_state" SET "state"=0; 
	UPDATE "current_session_id" SET "session"=0; 
	UPDATE states_metadata SET unique_states=1, recycled_states=0, collisions_count=0, deepcheck_success=0;

	-- 2. Remove foreign keys for stateful representation from the relation logs
	ALTER TABLE "Accepted_state_log" DROP CONSTRAINT IF EXISTS "ref_Accepted";
	ALTER TABLE "CurrReq_state_log" DROP CONSTRAINT IF EXISTS "ref_CurrReq";
	ALTER TABLE "Pending_state_log" DROP CONSTRAINT IF EXISTS "ref_Pending";
	ALTER TABLE "TrvlCost_state_log" DROP CONSTRAINT IF EXISTS "ref_TrvlCost";
	ALTER TABLE "TrvlMaxAmnt_state_log" DROP CONSTRAINT IF EXISTS "ref_TrvlMaxAmnt";
	ALTER TABLE "Rejected_state_log" DROP CONSTRAINT IF EXISTS "ref_Rejected";

	-- 3. Remove business foreign keys shifted to the state logs
	ALTER TABLE "TrvlCost_state_log" DROP CONSTRAINT IF EXISTS "fk_TrvlCost_CurrReq";
	ALTER TABLE "TrvlMaxAmnt_state_log" DROP CONSTRAINT IF EXISTS "fk_TrvlMaxAmnt_CurrReq";

	-- 4. Truncate state_log tables
	TRUNCATE "states"; 
	TRUNCATE "Accepted_state_log";
	TRUNCATE "CurrReq_state_log";
	TRUNCATE "Pending_state_log";
	TRUNCATE "TrvlCost_state_log";
	TRUNCATE "TrvlMaxAmnt_state_log";
	TRUNCATE "Rejected_state_log";

	-- 5. Remove information about all the possible action bindings
	TRUNCATE rvwreq_params;
	TRUNCATE fillrmb_params;
	TRUNCATE revwreimb_params;
	TRUNCATE startw_params;
	TRUNCATE endw_params;

	-- 6. Switch off TS generation
	UPDATE "TS_enabled" SET "enabled" = FALSE;
	TRUNCATE "TS";

	-- 7. Add foreign key constraints to connect tables with their state logs

	ALTER TABLE "Accepted_state_log" ADD CONSTRAINT "ref_Accepted" FOREIGN KEY ("rid")
		REFERENCES "Accepted" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "CurrReq_state_log" ADD CONSTRAINT "ref_CurrReq" FOREIGN KEY ("rid")
		REFERENCES "CurrReq" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "Pending_state_log" ADD CONSTRAINT "ref_Pending" FOREIGN KEY ("rid")
		REFERENCES "Pending" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "TrvlCost_state_log" ADD CONSTRAINT "ref_TrvlCost" FOREIGN KEY ("rid")
		REFERENCES "TrvlCost" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "TrvlMaxAmnt_state_log" ADD CONSTRAINT "ref_TrvlMaxAmnt" FOREIGN KEY ("rid")
		REFERENCES "TrvlMaxAmnt" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "Rejected_state_log" ADD CONSTRAINT "ref_Rejected" FOREIGN KEY ("rid")
		REFERENCES "Rejected" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	-- 8. Add foreign key constraints shifted from business relation tables to state log tables

	ALTER TABLE "TrvlCost_state_log" ADD CONSTRAINT "fk_TrvlCost_CurrReq" FOREIGN KEY ("state", "fid")
		REFERENCES "CurrReq_state_log" ("state","id") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

	ALTER TABLE "TrvlMaxAmnt_state_log" ADD CONSTRAINT "fk_TrvlMaxAmnt_CurrReq" FOREIGN KEY ("state","fid")
		REFERENCES "CurrReq_state_log" ("state","id") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;	

	-- 9. Clean up all the not-read-only tables

	TRUNCATE "Accepted" CASCADE;
	TRUNCATE "CurrReq" CASCADE;
	TRUNCATE "Pending" CASCADE;
	TRUNCATE "Rejected" CASCADE;
	TRUNCATE "TrvlCost" CASCADE;
	TRUNCATE "TrvlMaxAmnt" CASCADE;

	/*TRUNCATE "Accepted_dump";
	TRUNCATE "CurrReq_dump";
	TRUNCATE "Pending_dump";
	TRUNCATE "Rejected_dump";
	TRUNCATE "TrvlCost_dump";
	TRUNCATE "TrvlMaxAmnt_dump";

	TRUNCATE "Accepted_state_log_dump";
	TRUNCATE "CurrReq_state_log_dump";
	TRUNCATE "Pending_state_log_dump";
	TRUNCATE "TrvlCost_state_log_dump";
	TRUNCATE "TrvlMaxAmnt_state_log_dump";
	TRUNCATE "Rejected_state_log_dump";*/
	
	TRUNCATE "Accepted_endw_dump";
	TRUNCATE "Accepted_endw_state_log_dump";
	--TRUNCATE "CurrReq_endw_dump";
	TRUNCATE "CurrReq_endw_state_log_dump";
	TRUNCATE "CurrReq_fillrmb_dump";
	TRUNCATE "CurrReq_fillrmb_state_log_dump";
	TRUNCATE "CurrReq_revwreimb_dump";
	TRUNCATE "CurrReq_revwreimb_state_log_dump";
	TRUNCATE "CurrReq_rvwreq_dump";
	TRUNCATE "CurrReq_rvwreq_state_log_dump";
	TRUNCATE "CurrReq_startw_dump";
	TRUNCATE "CurrReq_startw_state_log_dump";
	TRUNCATE "Pending_startw_state_log_dump";
	TRUNCATE "Rejected_endw_dump";
	TRUNCATE "Rejected_endw_state_log_dump";
	TRUNCATE "TrvlCost_fillrmb_dump";
	TRUNCATE "TrvlCost_fillrmb_state_log_dump";
	--TRUNCATE "TrvlCost_endw_dump";
	TRUNCATE "TrvlCost_endw_state_log_dump";
	TRUNCATE "TrvlMaxAmnt_rvwreq_dump";
	TRUNCATE "TrvlMaxAmnt_rvwreq_state_log_dump";
	--TRUNCATE "TrvlMaxAmnt_endw_dump";
	TRUNCATE "TrvlMaxAmnt_endw_state_log_dump";
	
	TRUNCATE endw_eff_1_eval_res;
	TRUNCATE endw_eff_2_eval_res;
	TRUNCATE revwreimb_eff_1_eval_res;
	TRUNCATE revwreimb_eff_2_eval_res;

	TRUNCATE fillrmb_cost_service;
	TRUNCATE rvwreq_maxamnt_service;
	TRUNCATE rvwreq_status_service;


	-- 10. Restart sequences for RIDs and IDs

	ALTER SEQUENCE "inc_seq" RESTART WITH 1;
	ALTER SEQUENCE "id_seq" RESTART WITH 1;


	-- 11. Insert intial data

	INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Bob','NY',1,md5(row('Bob','NY',1)::TEXT)::uuid);
	INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Kriss','Genova',2,md5(row('Kriss','Genova',2)::TEXT)::uuid);

	--INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Bob','Genova',2,md5(row('Bob','Genova',2)::text)::uuid);
	--INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Kriss','NY',3,md5(row('Kriss','NY',3)::text)::uuid);
	/*INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Andy','Paris',4,md5(row('Andy','Paris',4)::text)::uuid);*/
	-- 12. Set curent state counter

	UPDATE "current_state" SET "state"=1; 
	--13. Insert intial data

	INSERT INTO "Pending_state_log" ("state","rid","id")
	(SELECT 1, "rid", "id" FROM "Pending");

	/*INSERT INTO "CurrReq_state_log" ("state","rid","id")
	(SELECT 1, "rid", "id" FROM "CurrReq");
	INSERT INTO "TrvlCost_state_log" ("state","rid","fid")
	(SELECT 1, "rid", "fid" FROM "TrvlCost");
	INSERT INTO "TrvlMaxAmnt_state_log" ("state","rid","fid")
	(SELECT 1, "rid", "fid" FROM "TrvlMaxAmnt");*/
	-- 14. Generate a first state with corresponding table hashes 

	INSERT INTO "states" SELECT 
		1, 
		md5(ARRAY(SELECT "phash" FROM "Accepted", "Accepted_state_log" 
							WHERE "state"=1
							AND "Accepted"."rid"="Accepted_state_log"."rid" 
							ORDER BY "Accepted_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "Pending", "Pending_state_log" 
							WHERE "state"=1 
							AND "Pending"."rid"="Pending_state_log"."rid" 
							ORDER BY "Pending_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "Rejected", "Rejected_state_log" 
							WHERE "state"=1
							AND "Rejected"."rid"="Rejected_state_log"."rid" 
							ORDER BY "Rejected_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "TrvlCost", "TrvlCost_state_log" 
							WHERE "state"=1
							AND "TrvlCost"."rid"="TrvlCost_state_log"."rid" 
							ORDER BY "TrvlCost_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log" 
							WHERE "state"=1 
							AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" 
							ORDER BY "TrvlMaxAmnt_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "CurrReq", "CurrReq_state_log" 
							WHERE "state"=1
							AND "CurrReq"."rid"="CurrReq_state_log"."rid" 
							ORDER BY "CurrReq_state_log"."rid" ASC)::TEXT)::uuid;

	-- 15. Turn on the TS generation
	UPDATE "TS_enabled" SET "enabled" = TRUE;
END;$$;


ALTER FUNCTION public.initialize() OWNER TO postgres;

--
-- Name: initialize(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION initialize(_size integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN

	-- 1. Null the curretn state counter
	UPDATE "current_state" SET "state"=0; 
	UPDATE "current_session_id" SET "session"=0; 
	UPDATE states_metadata SET unique_states=1, recycled_states=0, collisions_count=0, deepcheck_success=0;

	-- 2. Remove foreign keys for stateful representation from the relation logs
	ALTER TABLE "Accepted_state_log" DROP CONSTRAINT IF EXISTS "ref_Accepted";
	ALTER TABLE "CurrReq_state_log" DROP CONSTRAINT IF EXISTS "ref_CurrReq";
	ALTER TABLE "Pending_state_log" DROP CONSTRAINT IF EXISTS "ref_Pending";
	ALTER TABLE "TrvlCost_state_log" DROP CONSTRAINT IF EXISTS "ref_TrvlCost";
	ALTER TABLE "TrvlMaxAmnt_state_log" DROP CONSTRAINT IF EXISTS "ref_TrvlMaxAmnt";
	ALTER TABLE "Rejected_state_log" DROP CONSTRAINT IF EXISTS "ref_Rejected";

	-- 3. Remove business foreign keys shifted to the state logs
	ALTER TABLE "TrvlCost_state_log" DROP CONSTRAINT IF EXISTS "fk_TrvlCost_CurrReq";
	ALTER TABLE "TrvlMaxAmnt_state_log" DROP CONSTRAINT IF EXISTS "fk_TrvlMaxAmnt_CurrReq";

	-- 4. Truncate state_log tables
	TRUNCATE "states"; 
	TRUNCATE "Accepted_state_log";
	TRUNCATE "CurrReq_state_log";
	TRUNCATE "Pending_state_log";
	TRUNCATE "TrvlCost_state_log";
	TRUNCATE "TrvlMaxAmnt_state_log";
	TRUNCATE "Rejected_state_log";

	-- 5. Remove information about all the possible action bindings
	TRUNCATE rvwreq_params;
	TRUNCATE fillrmb_params;
	TRUNCATE revwreimb_params;
	TRUNCATE startw_params;
	TRUNCATE endw_params;

	-- 6. Switch off TS generation
	UPDATE "TS_enabled" SET "enabled" = FALSE;
	TRUNCATE "TS";

	-- 7. Add foreign key constraints to connect tables with their state logs

	ALTER TABLE "Accepted_state_log" ADD CONSTRAINT "ref_Accepted" FOREIGN KEY ("rid")
		REFERENCES "Accepted" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "CurrReq_state_log" ADD CONSTRAINT "ref_CurrReq" FOREIGN KEY ("rid")
		REFERENCES "CurrReq" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "Pending_state_log" ADD CONSTRAINT "ref_Pending" FOREIGN KEY ("rid")
		REFERENCES "Pending" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "TrvlCost_state_log" ADD CONSTRAINT "ref_TrvlCost" FOREIGN KEY ("rid")
		REFERENCES "TrvlCost" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "TrvlMaxAmnt_state_log" ADD CONSTRAINT "ref_TrvlMaxAmnt" FOREIGN KEY ("rid")
		REFERENCES "TrvlMaxAmnt" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	ALTER TABLE "Rejected_state_log" ADD CONSTRAINT "ref_Rejected" FOREIGN KEY ("rid")
		REFERENCES "Rejected" ("rid") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE NOT DEFERRABLE;

	-- 8. Add foreign key constraints shifted from business relation tables to state log tables

	ALTER TABLE "TrvlCost_state_log" ADD CONSTRAINT "fk_TrvlCost_CurrReq" FOREIGN KEY ("state", "fid")
		REFERENCES "CurrReq_state_log" ("state","id") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

	ALTER TABLE "TrvlMaxAmnt_state_log" ADD CONSTRAINT "fk_TrvlMaxAmnt_CurrReq" FOREIGN KEY ("state","fid")
		REFERENCES "CurrReq_state_log" ("state","id") MATCH SIMPLE
		ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;	

	-- 9. Clean up all the not-read-only tables

	TRUNCATE "Accepted" CASCADE;
	TRUNCATE "CurrReq" CASCADE;
	TRUNCATE "Pending" CASCADE;
	TRUNCATE "Rejected" CASCADE;
	TRUNCATE "TrvlCost" CASCADE;
	TRUNCATE "TrvlMaxAmnt" CASCADE;

	/*TRUNCATE "Accepted_dump";
	TRUNCATE "CurrReq_dump";
	TRUNCATE "Pending_dump";
	TRUNCATE "Rejected_dump";
	TRUNCATE "TrvlCost_dump";
	TRUNCATE "TrvlMaxAmnt_dump";

	TRUNCATE "Accepted_state_log_dump";
	TRUNCATE "CurrReq_state_log_dump";
	TRUNCATE "Pending_state_log_dump";
	TRUNCATE "TrvlCost_state_log_dump";
	TRUNCATE "TrvlMaxAmnt_state_log_dump";
	TRUNCATE "Rejected_state_log_dump";*/
	
	TRUNCATE "Accepted_endw_dump";
	TRUNCATE "Accepted_endw_state_log_dump";
	--TRUNCATE "CurrReq_endw_dump";
	TRUNCATE "CurrReq_endw_state_log_dump";
	TRUNCATE "CurrReq_fillrmb_dump";
	TRUNCATE "CurrReq_fillrmb_state_log_dump";
	TRUNCATE "CurrReq_revwreimb_dump";
	TRUNCATE "CurrReq_revwreimb_state_log_dump";
	TRUNCATE "CurrReq_rvwreq_dump";
	TRUNCATE "CurrReq_rvwreq_state_log_dump";
	TRUNCATE "CurrReq_startw_dump";
	TRUNCATE "CurrReq_startw_state_log_dump";
	TRUNCATE "Pending_startw_state_log_dump";
	TRUNCATE "Rejected_endw_dump";
	TRUNCATE "Rejected_endw_state_log_dump";
	TRUNCATE "TrvlCost_fillrmb_dump";
	TRUNCATE "TrvlCost_fillrmb_state_log_dump";
	--TRUNCATE "TrvlCost_endw_dump";
	TRUNCATE "TrvlCost_endw_state_log_dump";
	TRUNCATE "TrvlMaxAmnt_rvwreq_dump";
	TRUNCATE "TrvlMaxAmnt_rvwreq_state_log_dump";
	--TRUNCATE "TrvlMaxAmnt_endw_dump";
	TRUNCATE "TrvlMaxAmnt_endw_state_log_dump";
	
	TRUNCATE endw_eff_1_eval_res;
	TRUNCATE endw_eff_2_eval_res;
	TRUNCATE revwreimb_eff_1_eval_res;
	TRUNCATE revwreimb_eff_2_eval_res;

	TRUNCATE fillrmb_cost_service;
	TRUNCATE rvwreq_maxamnt_service;
	TRUNCATE rvwreq_status_service;


	-- 10. Restart sequences for RIDs and IDs

	ALTER SEQUENCE "inc_seq" RESTART WITH 1;
	ALTER SEQUENCE "id_seq" RESTART WITH 1;


	-- 11. Insert intial data
	INSERT INTO "Pending"(empl,dest,id,phash)
	(SELECT DISTINCT  
		"Empl".empl,
		"Dest".dest, 
		nextval('id_seq'::regclass),
		md5(row("Empl".empl,"Dest".dest, currval('id_seq'::regclass))::TEXT)::uuid
	FROM "Dest", "Empl" LIMIT _size);

	--INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Bob','NY',1,md5(row('Bob','NY',1)::TEXT)::uuid);
	--INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Kriss','Genova',2,md5(row('Kriss','Genova',2)::TEXT)::uuid);

	--INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Bob','Genova',2,md5(row('Bob','Genova',2)::text)::uuid);
	--INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Kriss','NY',3,md5(row('Kriss','NY',3)::text)::uuid);
	/*INSERT INTO "Pending"(empl,dest,id,phash) VALUES('Andy','Paris',4,md5(row('Andy','Paris',4)::text)::uuid);*/
	-- 12. Set curent state counter

	UPDATE "current_state" SET "state"=1; 
	--13. Insert intial data

	INSERT INTO "Pending_state_log" ("state","rid","id")
	(SELECT 1, "rid", "id" FROM "Pending");

	/*INSERT INTO "CurrReq_state_log" ("state","rid","id")
	(SELECT 1, "rid", "id" FROM "CurrReq");
	INSERT INTO "TrvlCost_state_log" ("state","rid","fid")
	(SELECT 1, "rid", "fid" FROM "TrvlCost");
	INSERT INTO "TrvlMaxAmnt_state_log" ("state","rid","fid")
	(SELECT 1, "rid", "fid" FROM "TrvlMaxAmnt");*/
	-- 14. Generate a first state with corresponding table hashes 

	INSERT INTO "states" SELECT 
		1, 
		md5(ARRAY(SELECT "phash" FROM "Accepted", "Accepted_state_log" 
							WHERE "state"=1
							AND "Accepted"."rid"="Accepted_state_log"."rid" 
							ORDER BY "Accepted_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "Pending", "Pending_state_log" 
							WHERE "state"=1 
							AND "Pending"."rid"="Pending_state_log"."rid" 
							ORDER BY "Pending_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "Rejected", "Rejected_state_log" 
							WHERE "state"=1
							AND "Rejected"."rid"="Rejected_state_log"."rid" 
							ORDER BY "Rejected_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "TrvlCost", "TrvlCost_state_log" 
							WHERE "state"=1
							AND "TrvlCost"."rid"="TrvlCost_state_log"."rid" 
							ORDER BY "TrvlCost_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log" 
							WHERE "state"=1 
							AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" 
							ORDER BY "TrvlMaxAmnt_state_log"."rid" ASC)::TEXT)::uuid,
		md5(ARRAY(SELECT "phash" FROM "CurrReq", "CurrReq_state_log" 
							WHERE "state"=1
							AND "CurrReq"."rid"="CurrReq_state_log"."rid" 
							ORDER BY "CurrReq_state_log"."rid" ASC)::TEXT)::uuid;

	-- 15. Turn on the TS generation
	UPDATE "TS_enabled" SET "enabled" = TRUE;
END;$$;


ALTER FUNCTION public.initialize(_size integer) OWNER TO postgres;

--
-- Name: insert_accepted(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_accepted() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
	hash TEXT;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	SELECT md5(row(NEW."empl", NEW."dest", NEW."amount", NEW."id")::text) INTO hash;
	
	IF EXISTS(SELECT 1 FROM "Accepted" WHERE "Accepted"."phash"=hash)
	THEN 
		INSERT INTO "Accepted_state_log" ("state","rid","id") 
		(SELECT "new_state",
				"Accepted"."rid",
				"Accepted"."id"
				--NEW."id"
		FROM "Accepted" WHERE "Accepted"."phash"=hash);
		RETURN NULL;
	ELSE 
		NEW."phash":=hash;
		RETURN NEW;
	END IF;
END $$;


ALTER FUNCTION public.insert_accepted() OWNER TO postgres;

--
-- Name: insert_currreq(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_currreq() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
	hash TEXT;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	SELECT md5(row(NEW."empl", NEW."dest", NEW."status", NEW."id")::text) INTO hash;
	-- if already exists an entry, make it's duplicate with the same ID
	IF EXISTS(SELECT 1 FROM "CurrReq" WHERE "CurrReq"."phash"=hash)
	THEN 
		INSERT INTO "CurrReq_state_log" ("state","rid","id") 
		(SELECT "new_state",
				"CurrReq"."rid",
				"CurrReq"."id"
				--NEW."id"
		FROM "CurrReq" WHERE "CurrReq"."phash"=hash);
		RETURN NULL;
	ELSE 
		NEW."phash":=hash;
		RETURN NEW;
	END IF;
END $$;


ALTER FUNCTION public.insert_currreq() OWNER TO postgres;

--
-- Name: insert_pending(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_pending() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
	hash TEXT;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	SELECT md5(row(NEW."empl", NEW."dest", NEW."id")::text) INTO hash;
	
	IF EXISTS(SELECT 1 FROM "Pending" WHERE "Pending"."phash"=hash)
	THEN 
		INSERT INTO "Pending_state_log" ("state","rid","id") 
		(SELECT "new_state",
				"Pending"."rid",
				"Pending"."id"
		FROM "Pending" WHERE "Pending"."phash"=hash);
		RETURN NULL;
	ELSE 
		NEW."phash":=hash;
		RETURN NEW;
	END IF;
END $$;


ALTER FUNCTION public.insert_pending() OWNER TO postgres;

--
-- Name: insert_rejected(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_rejected() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
	hash TEXT;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	SELECT md5(row(NEW."empl", NEW."dest", NEW."id")::text) INTO hash;
	
	IF EXISTS(SELECT 1 FROM "Rejected" WHERE "Rejected"."phash"=hash)
	THEN 
		INSERT INTO "Rejected_state_log" ("state","rid","id") 
		(SELECT "new_state",
				"Rejected"."rid",
				"Rejected"."id"
		FROM "Rejected" WHERE "Rejected"."phash"=hash);
		RETURN NULL;
	ELSE 
		NEW."phash":=hash;
		RETURN NEW;
	END IF;
END $$;


ALTER FUNCTION public.insert_rejected() OWNER TO postgres;

--
-- Name: insert_trvlcost(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_trvlcost() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
	hash TEXT;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	--SELECT md5(row(NEW."cost",NEW."id",NEW."fid")::text) INTO hash;
	SELECT md5(row(NEW."cost",NEW."fid")::text) INTO hash;
	
	IF EXISTS(SELECT 1 FROM "TrvlCost" WHERE "TrvlCost"."phash"=hash)
	THEN 
		INSERT INTO "TrvlCost_state_log" ("state","rid","fid") 
		(SELECT "new_state",
				"TrvlCost"."rid",
				"TrvlCost"."fid"
		FROM "TrvlCost" WHERE "TrvlCost"."phash"=hash);
		RETURN NULL;
	ELSE 
		NEW."phash":=hash;
		RETURN NEW;
	END IF;
END $$;


ALTER FUNCTION public.insert_trvlcost() OWNER TO postgres;

--
-- Name: insert_trvlmaxamnt(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_trvlmaxamnt() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
	hash TEXT;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	--SELECT md5(row(NEW."maxAmnt",NEW."id",NEW."fid")::text) INTO hash;
	SELECT md5(row(NEW."maxAmnt",NEW."fid")::text) INTO hash;
	
	IF EXISTS(SELECT 1 FROM "TrvlMaxAmnt" WHERE "TrvlMaxAmnt"."phash"=hash)
	THEN 
		INSERT INTO "TrvlMaxAmnt_state_log" ("state","rid","fid") 
		(SELECT "new_state",
				"TrvlMaxAmnt"."rid",
				"TrvlMaxAmnt"."fid"
		FROM "TrvlMaxAmnt" WHERE "TrvlMaxAmnt"."phash"=hash);
		RETURN NULL;
	ELSE 
		NEW."phash":=hash;
		RETURN NEW;
	END IF;
END $$;


ALTER FUNCTION public.insert_trvlmaxamnt() OWNER TO postgres;

--
-- Name: no_delete(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION no_delete() RETURNS trigger
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
   RAISE EXCEPTION 'You cannot delete this element!';
END;$$;


ALTER FUNCTION public.no_delete() OWNER TO postgres;

--
-- Name: pending_state_map(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pending_state_map(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Pending_state_log"."id", "Pending"."empl", "Pending"."dest", "Pending_state_log"."rid"
		FROM "Pending", "Pending_state_log"
		WHERE "state"=_state AND "Pending"."rid"="Pending_state_log"."rid";
END$$;


ALTER FUNCTION public.pending_state_map(_state integer) OWNER TO postgres;

--
-- Name: pending_state_map_until(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pending_state_map_until(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Pending_state_log"."id", "Pending"."empl", "Pending"."dest", "Pending_state_log"."rid"
		FROM "Pending", "Pending_state_log"
		WHERE "state"<_state AND "state">1 AND "Pending"."rid"="Pending_state_log"."rid";
END$$;


ALTER FUNCTION public.pending_state_map_until(_state integer) OWNER TO postgres;

--
-- Name: pending_state_view(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION pending_state_view(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Pending_state_log"."id", "Pending"."empl", "Pending"."dest"
		FROM "Pending", "Pending_state_log"
		WHERE "state"=_state AND "Pending"."rid"="Pending_state_log"."rid"
		ORDER BY "Pending_state_log"."id" ASC;
END$$;


ALTER FUNCTION public.pending_state_view(_state integer) OWNER TO postgres;

--
-- Name: recycle_integer(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION recycle_integer(_state integer) RETURNS TABLE(val integer)
    LANGUAGE plpgsql IMMUTABLE ROWS 1000000
    AS $$DECLARE 
	curr_state INTEGER; --current state
BEGIN
	SELECT "current_state"."state" FROM "current_state" INTO "curr_state"; --take the current state
	RETURN QUERY 
		SELECT DISTINCT trvlmaxamnt_1."maxAmnt" 
				FROM "TrvlMaxAmnt" AS trvlmaxamnt_1, "TrvlMaxAmnt_state_log" AS trvlmaxamnt_state_log_1
				WHERE trvlmaxamnt_state_log_1."state"<"curr_state"
				AND trvlmaxamnt_state_log_1."state">1 
				AND trvlmaxamnt_1."rid"=trvlmaxamnt_state_log_1."rid"
				AND NOT EXISTS 
				(SELECT 1 
						FROM "TrvlMaxAmnt" AS trvlmaxamnt_2, "TrvlMaxAmnt_state_log" AS trvlmaxamnt_state_log_2
						WHERE trvlmaxamnt_state_log_2."state"="_state"
						AND trvlmaxamnt_2.rid=trvlmaxamnt_state_log_2.rid 
						AND trvlmaxamnt_2."maxAmnt"=trvlmaxamnt_1."maxAmnt")
		UNION
		SELECT DISTINCT trvlcost_1."cost"
				FROM "TrvlCost" AS trvlcost_1, "TrvlCost_state_log" AS trvlcost_state_log_1
				WHERE trvlcost_state_log_1."state"<"curr_state"
				AND trvlcost_state_log_1."state">1 
				AND trvlcost_1."rid"=trvlcost_state_log_1."rid"
				AND NOT EXISTS 
				(SELECT 1 
						FROM "TrvlCost" AS trvlcost_2, "TrvlCost_state_log" AS trvlcost_state_log_2
						WHERE trvlcost_state_log_2."state"="_state"
						AND trvlcost_2.rid=trvlcost_state_log_2.rid 
						AND trvlcost_1."cost"=trvlcost_2."cost")
		UNION
		SELECT DISTINCT accepted_1."amount"
				FROM "Accepted" AS accepted_1, "Accepted_state_log" AS accepted_state_log_1
				WHERE accepted_state_log_1."state"<"curr_state" 
				AND accepted_state_log_1."state">1 
				AND accepted_1."rid"=accepted_state_log_1."rid"
				AND NOT EXISTS 
				(SELECT 1 
						FROM "Accepted" AS accepted_2, "Accepted_state_log" AS accepted_state_log_2
						WHERE accepted_state_log_2."state"="_state" 
						AND accepted_2.rid=accepted_state_log_2.rid 
						AND accepted_1."amount"=accepted_2."amount")
		--UNION
		--SELECT "value" FROM "maxamnt_allowed_values"
		ORDER BY 1 ASC;
END$$;


ALTER FUNCTION public.recycle_integer(_state integer) OWNER TO postgres;

--
-- Name: recycle_string(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION recycle_string(_state integer) RETURNS TABLE(val character varying)
    LANGUAGE plpgsql IMMUTABLE ROWS 1000000
    AS $$DECLARE 
	curr_state INTEGER; --current state
BEGIN
	SELECT "current_state"."state" FROM "current_state" INTO "curr_state"; --take the current state
	RETURN QUERY 
		SELECT DISTINCT pending_1."empl"
				FROM "Pending" AS pending_1, "Pending_state_log" AS pending_state_log_1
				WHERE pending_state_log_1."state"<"curr_state"
				AND pending_state_log_1."state">1
				AND pending_1."rid" = pending_state_log_1."rid"
				AND NOT EXISTS
				(SELECT 1
						FROM "Pending" AS pending_2, "Pending_state_log" AS pending_state_log_2
						WHERE pending_state_log_2."state"="_state"
						AND pending_2."rid" = pending_state_log_2."rid"
						AND pending_1."empl"=pending_2."empl")
		UNION
		SELECT DISTINCT pending_1."dest"
				FROM "Pending" AS pending_1, "Pending_state_log" AS pending_state_log_1
				WHERE pending_state_log_1."state"<"curr_state"
				AND pending_state_log_1."state">1
				AND pending_1."rid" = pending_state_log_1."rid"
				AND NOT EXISTS
				(SELECT 1
						FROM "Pending" AS pending_2, "Pending_state_log" AS pending_state_log_2
						WHERE pending_state_log_2."state"="_state"
						AND pending_2."rid" = pending_state_log_2."rid"
						AND pending_1."dest"=pending_2."dest")
		UNION
		SELECT DISTINCT currreq_1."empl"
				FROM "CurrReq" AS currreq_1, "CurrReq_state_log" AS currreq_state_log_1
				WHERE currreq_state_log_1."state"<"curr_state"
				AND currreq_state_log_1."state">1
				AND currreq_1."rid" = currreq_state_log_1."rid"
				AND NOT EXISTS
				(SELECT 1
						FROM "CurrReq" AS currreq_2, "CurrReq_state_log" AS currreq_state_log_2
						WHERE currreq_state_log_2."state"="_state"
						AND currreq_2."rid" = currreq_state_log_2."rid"
						AND currreq_1."empl"=currreq_2."empl")
		UNION
		SELECT DISTINCT currreq_1."dest"
				FROM "CurrReq" AS currreq_1, "CurrReq_state_log" AS currreq_state_log_1
				WHERE currreq_state_log_1."state"<"curr_state"
				AND currreq_state_log_1."state">1
				AND currreq_1."rid" = currreq_state_log_1."rid"
				AND NOT EXISTS
				(SELECT 1
						FROM "CurrReq" AS currreq_2, "CurrReq_state_log" AS currreq_state_log_2
						WHERE currreq_state_log_2."state"="_state"
						AND currreq_2."rid" = currreq_state_log_2."rid"
						AND currreq_1."dest"=currreq_2."dest")
		UNION
		SELECT DISTINCT currreq_1."status"
				FROM "CurrReq" AS currreq_1, "CurrReq_state_log" AS currreq_state_log_1
				WHERE currreq_state_log_1."state"<"curr_state"
				AND currreq_state_log_1."state">1
				AND currreq_1."rid" = currreq_state_log_1."rid"
				AND NOT EXISTS
				(SELECT 1
						FROM "CurrReq" AS currreq_2, "CurrReq_state_log" AS currreq_state_log_2
						WHERE currreq_state_log_2."state"="_state"
						AND currreq_2."rid" = currreq_state_log_2."rid"
						AND currreq_1."status"=currreq_2."status")
		ORDER BY 1 ASC;
END$$;


ALTER FUNCTION public.recycle_string(_state integer) OWNER TO postgres;

--
-- Name: rejected_state_map(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rejected_state_map(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Rejected_state_log"."id", "Rejected"."empl", "Rejected"."dest", "Rejected_state_log"."rid"
		FROM "Rejected", "Rejected_state_log"  
		WHERE "state"=_state AND "Rejected"."rid"="Rejected_state_log"."rid";
END$$;


ALTER FUNCTION public.rejected_state_map(_state integer) OWNER TO postgres;

--
-- Name: rejected_state_map_until(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rejected_state_map_until(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Rejected_state_log"."id", "Rejected"."empl", "Rejected"."dest", "Rejected_state_log"."rid"
		FROM "Rejected", "Rejected_state_log"  
		WHERE "state"<_state AND "state">1 AND "Rejected"."rid"="Rejected_state_log"."rid";
END$$;


ALTER FUNCTION public.rejected_state_map_until(_state integer) OWNER TO postgres;

--
-- Name: rejected_state_view(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rejected_state_view(_state integer) RETURNS TABLE(id integer, empl character varying, dest character varying)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "Rejected_state_log"."id", "Rejected"."empl", "Rejected"."dest"
		FROM "Rejected", "Rejected_state_log"  
		WHERE "state"=_state AND "Rejected"."rid"="Rejected_state_log"."rid"
		ORDER BY "Rejected_state_log"."id" ASC;
END$$;


ALTER FUNCTION public.rejected_state_view(_state integer) OWNER TO postgres;

--
-- Name: revwreimb_ca_eval(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION revwreimb_ca_eval(_state integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	IF NOT EXISTS 
	(SELECT "state" FROM "revwreimb_params" WHERE "state"="_state")
	THEN
	INSERT INTO "revwreimb_params" ("state", "cost", "id_currreq", "checked")
		(
		SELECT 
			"_state", 
			"TrvlCost"."cost",
			"CurrReq"."id",
			FALSE
		FROM "CurrReq", "CurrReq_state_log", "TrvlCost", "TrvlCost_state_log"
		WHERE "CurrReq_state_log"."state"=_state 
		AND "CurrReq"."rid"="CurrReq_state_log"."rid" 
		AND "TrvlCost_state_log"."state"=_state 
		AND "TrvlCost"."rid"="TrvlCost_state_log"."rid" 
		AND "CurrReq_state_log"."id"="TrvlCost_state_log"."fid"
		AND "CurrReq"."status" = 'complete'); 
	END IF;
	-- having state mappers we don't need to consider states: only IDs matter 
	-- given that CurrReq's ID is the only one in a given state, the uniqueness of TrvlCost's FID is stritcly implied
END$$;


ALTER FUNCTION public.revwreimb_ca_eval(_state integer) OWNER TO postgres;

--
-- Name: revwreimb_eff_eval(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION revwreimb_eff_eval(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_session_id INTEGER;
BEGIN
	UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	-- evaluate effect 1 precondition query
	INSERT INTO "revwreimb_eff_1_eval_res"  ("id_currreq","session_id") 
		(
		SELECT "revwreimb_params"."id_currreq", "curr_session_id"
		FROM "revwreimb_params"--,"CurrReq_state_log"
		WHERE EXISTS (SELECT 1 
					FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log"
					WHERE "TrvlMaxAmnt_state_log"."state"=_state 
					AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" 
					AND "TrvlMaxAmnt_state_log"."fid" = "revwreimb_params"."id_currreq"
					AND "revwreimb_params"."cost"<="TrvlMaxAmnt"."maxAmnt")
		AND "revwreimb_params"."param_id" = "param_rid");
--		AND "CurrReq_state_log"."state"="_state";

-- evaluate effect 2 precondition query
	INSERT INTO "revwreimb_eff_2_eval_res"  ("id_currreq","session_id") 
		(
		SELECT "revwreimb_params"."id_currreq", "curr_session_id"
		FROM "revwreimb_params"--, "CurrReq_state_log"
		WHERE EXISTS (SELECT 1 
					FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log"
					WHERE "TrvlMaxAmnt_state_log"."state"=_state 
					AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" 
					AND "TrvlMaxAmnt_state_log"."fid" = "revwreimb_params"."id_currreq"
					AND "revwreimb_params"."cost">"TrvlMaxAmnt"."maxAmnt")
		AND "revwreimb_params"."param_id" = "param_rid");
		--AND "CurrReq_state_log"."state"="_state";
-- no services defined

 --5. Mark used action parameters as checked
	UPDATE "revwreimb_params" SET "checked"=TRUE 
	WHERE "revwreimb_params"."param_id" = "param_rid"
	AND "revwreimb_params"."state" = "_state";
END$$;


ALTER FUNCTION public.revwreimb_eff_eval(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: revwreimb_eff_exec(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION revwreimb_eff_exec(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_state INTEGER; --current state
	curr_session_id INTEGER;
	hash_accepted_new UUID;
	hash_pending_new UUID;
	hash_rejected_new UUID;
	hash_trvlcost_new UUID;
	hash_trvlmaxamnt_new UUID;
	hash_currreq_new UUID;
	collision_state INTEGER;
	collision_Accepted INTEGER := 0;
	collision_Pending INTEGER := 0;
	collision_Rejected INTEGER := 0;
	collision_TrvlCost INTEGER := 0;
	collision_TrvlMaxAmnt INTEGER := 0;
	collision_CurrReq INTEGER := 0;
	TS_flag BOOLEAN;
BEGIN
	SELECT "current_state"."state" FROM "current_state" INTO "curr_state"; --take the current state
	--UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- PROBLEM: we don't know how to treat hashes in actions with a couple of effects where at least tцo effects are executable and there is at least one relation that appears in ADD and/or DEL lists of these two effects
	-- SOLUTION: hashes are computed using common tables R_dump and R_state_log_dump
	-- NOTE: whenever there is R that appears in at least two ADD and/or DEL lists, we should insert in it only "fresh" values, i.e. those that haven't been yet inserted into R_dump; moreover, if there one of the DEL lists 
	-- stipulates to remove one of the values inserted into R_dump, then one should physically remove it from R_dump; at last, we should preserve the uniqueness and consistency of the values in R_state_log_dump as well
	-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	--1. Insert data defined in the ADD list using temporary tables [action]_eff[_i]_eval generated at the effect evaluation stage

	
	-- first conditional effect
	IF EXISTS(SELECT 1 FROM "revwreimb_eff_1_eval_res" WHERE "revwreimb_eff_1_eval_res"."session_id"="curr_session_id")
	THEN
		INSERT INTO "CurrReq_revwreimb_dump" ("empl", "dest", "status", "phash", "id", "session_id" )
		(SELECT "CurrReq"."empl", 
				"CurrReq"."dest", 
				'reimbursed' ,
				md5(row("CurrReq"."empl", "CurrReq"."dest", 'reimbursed', "revwreimb_eff_1_eval_res"."id_currreq")::text)::uuid,
				"revwreimb_eff_1_eval_res"."id_currreq",
				"curr_session_id"
		FROM "CurrReq_state_log","CurrReq","revwreimb_params","revwreimb_eff_1_eval_res"
		WHERE "CurrReq_state_log"."state"=_state
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "CurrReq_state_log"."id" = "revwreimb_eff_1_eval_res"."id_currreq"
		AND "revwreimb_eff_1_eval_res"."session_id"="curr_session_id"
		AND "revwreimb_params"."param_id"="param_rid");
		
		-- copy all the rest that has not been affected by ADD (or UPDATE)
		INSERT INTO "CurrReq_revwreimb_state_log_dump" ("session_id","rid","id")
		(SELECT "curr_session_id", "CurrReq_state_log"."rid", "CurrReq_state_log"."id"
			FROM "CurrReq_state_log","CurrReq", "revwreimb_params", "revwreimb_eff_1_eval_res"
			WHERE "CurrReq_state_log"."state"=_state
			AND "CurrReq"."rid"="CurrReq_state_log"."rid"
			AND "revwreimb_params"."param_id" = "param_rid"
			AND "CurrReq_state_log"."id"<>"revwreimb_eff_1_eval_res"."id_currreq"
			AND "revwreimb_eff_1_eval_res"."session_id"="curr_session_id");
	END IF;

	-- second conditional effect
	IF EXISTS(SELECT 1 FROM "revwreimb_eff_2_eval_res" WHERE "revwreimb_eff_2_eval_res"."session_id"="curr_session_id")
	THEN
		INSERT INTO "CurrReq_revwreimb_dump" ("empl", "dest", "status", "phash", "id", "session_id" )
		(SELECT "CurrReq"."empl", 
				"CurrReq"."dest", 
				'rejected' ,
				md5(row("CurrReq"."empl", "CurrReq"."dest", 'rejected', "revwreimb_eff_2_eval_res"."id_currreq")::text)::uuid,
				"revwreimb_eff_2_eval_res"."id_currreq",
				"curr_session_id"
		FROM "CurrReq_state_log","CurrReq","revwreimb_params","revwreimb_eff_2_eval_res"
		WHERE "CurrReq_state_log"."state"=_state
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "CurrReq_state_log"."id" = "revwreimb_eff_2_eval_res"."id_currreq"
		AND "revwreimb_eff_2_eval_res"."session_id"="curr_session_id"
		AND "revwreimb_params"."param_id"="param_rid");
		
		-- copy all the rest that has not been affected by ADD (or UPDATE)
		INSERT INTO "CurrReq_revwreimb_state_log_dump" ("session_id","rid","id")
		(SELECT "curr_session_id", "CurrReq_state_log"."rid", "CurrReq_state_log"."id"
			FROM "CurrReq_state_log","CurrReq", "revwreimb_params", "revwreimb_eff_2_eval_res"
			WHERE "CurrReq_state_log"."state"=_state
			AND "CurrReq"."rid"="CurrReq_state_log"."rid"
			AND "revwreimb_params"."param_id" = "param_rid"
			AND "CurrReq_state_log"."id"<>"revwreimb_eff_2_eval_res"."id_currreq"
			AND "revwreimb_eff_2_eval_res"."session_id"="curr_session_id");
	END IF;


	
	--3. Calculate state hash for each table, insert it into states (if at least one hash value is unique) and add a new (curr,next) pair to the TS table
	--3.1. Prepare hash values for the untouched data (i.e., we can use the current state)


	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Pending", "Pending_state_log" 
	WHERE "state"=_state 
	AND "Pending"."rid"="Pending_state_log"."rid" 
	ORDER BY "Pending_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_pending_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Accepted", "Accepted_state_log" 
	WHERE "state"=_state 
	AND "Accepted"."rid"="Accepted_state_log"."rid" 
	ORDER BY "Accepted_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_accepted_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Rejected", "Rejected_state_log" 
	WHERE "state"=_state 
	AND "Rejected"."rid"="Rejected_state_log"."rid" 
	ORDER BY "Rejected_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_rejected_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log" 
	WHERE "state"=_state 
	AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" 
	ORDER BY "TrvlMaxAmnt_state_log"."fid" ASC)::TEXT)::uuid 
	INTO hash_trvlmaxamnt_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlCost", "TrvlCost_state_log" 
	WHERE "state"=_state 
	AND "TrvlCost"."rid"="TrvlCost_state_log"."rid" 
	ORDER BY "TrvlCost_state_log"."fid" ASC)::TEXT)::uuid 
	INTO hash_trvlcost_new;
	
	--generate hashes in a special way only for those relations which have been also non-temporally updated
	-- NOTE: here we are cheating since the structure of our two effects is essentially XOR-like
	SELECT 
		md5(ARRAY(
				SELECT res.phash FROM 
				(SELECT "CurrReq_revwreimb_dump"."id", "CurrReq_revwreimb_dump"."phash" --take hash of entries in tmp table
					FROM "CurrReq_revwreimb_dump" 
					WHERE "CurrReq_revwreimb_dump"."session_id"="curr_session_id"
					UNION
				SELECT "CurrReq"."id", "CurrReq"."phash" --take hash of entries in the original table using tmp temporal portrait (only copied historical values)
					FROM "CurrReq", "CurrReq_revwreimb_state_log_dump" 
					WHERE "CurrReq"."rid"="CurrReq_revwreimb_state_log_dump"."rid" 
					AND "CurrReq_revwreimb_state_log_dump"."session_id" = "curr_session_id" 
				ORDER BY id ASC) AS res)::TEXT)::uuid
	INTO hash_currreq_new;



	--3.2. Check if a tuple compiled out of new hash values can have collisions by conferming that there are no states with exactly the same hashe values
	SELECT COALESCE(MAX(state),0) FROM "states" 
	WHERE "hash_Accepted"=hash_accepted_new
	AND "hash_Pending"=hash_pending_new
	AND "hash_Rejected"=hash_rejected_new
	AND "hash_TrvlCost"=hash_trvlcost_new
	AND "hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "hash_CurrReq"=hash_currreq_new
	INTO "collision_state"; --assume that the first state has a value 1

	-- just for debugging 
	UPDATE states_metadata SET collisions_count=
	collisions_count +
	(SELECT COALESCE(COUNT("state"),0) FROM "states" 
	WHERE "states"."hash_Accepted"=hash_accepted_new
	AND "states"."hash_Pending"=hash_pending_new
	AND "states"."hash_Rejected"=hash_rejected_new
	AND "states"."hash_TrvlCost"=hash_trvlcost_new
	AND "states"."hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "states"."hash_CurrReq"=hash_currreq_new);


	-- just for debugging
	IF "collision_state"<>0 THEN
		SELECT COUNT(1) FROM (
		SELECT * FROM accepted_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM accepted_state_view("collision_state") AS t2) AS res INTO collision_Accepted;

		SELECT COUNT(1) FROM (
		SELECT * FROM pending_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM pending_state_view("collision_state") AS t2) AS res INTO collision_Pending;

		SELECT COUNT(1) FROM (
		SELECT * FROM rejected_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM rejected_state_view("collision_state") AS t2) AS res INTO collision_Rejected;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlcost_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlcost_state_view("collision_state") AS t2) AS res INTO collision_TrvlCost;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlmaxamnt_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlmaxamnt_state_view("collision_state") AS t2) AS res INTO collision_TrvlMaxAmnt;

		SELECT COUNT(1) FROM (
		SELECT * FROM currreq_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM currreq_state_view("collision_state") AS t2) AS res INTO collision_CurrReq;

		-- just for debugging
		IF (collision_CurrReq + 
			collision_TrvlMaxAmnt + 
			collision_TrvlCost + 
			collision_Rejected + 
			collision_Pending + 
			collision_Accepted=0) THEN
			"collision_state":=0;
			UPDATE states_metadata SET deepcheck_success=deepcheck_success+1;
		END IF;
	END IF;
	--3.3. If a state has not been generated yet (i.e., collision_state=0), add it to the states table 
	IF "collision_state"=0 THEN

	-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "CurrReq"("empl", "dest", "status", "id", "rid", "phash") 
		(SELECT "empl", "dest", "status", "id", "rid", "phash" FROM "CurrReq_revwreimb_dump" 
			WHERE "CurrReq_revwreimb_dump"."session_id" = "curr_session_id"
			AND NOT EXISTS 
			(SELECT 1 FROM "CurrReq" 
			WHERE "CurrReq"."phash"="CurrReq_revwreimb_dump"."phash"));

		-- now, for each NEW added data create a corresponding entry in the temporal portrait of CurrReq (i.e., CurrReq_state_log)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM "CurrReq","CurrReq_revwreimb_dump" 
		WHERE "CurrReq"."phash"="CurrReq_revwreimb_dump"."phash"
		AND "CurrReq_revwreimb_dump"."session_id" = "curr_session_id"
		--AND "CurrReq"."rid"="CurrReq_revwreimb_dump"."rid"
		);

		-- now, copy all the data of CurrReq that has not been changed (i.e., the one we put in CurrReq_state_log_tmp)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM  "CurrReq_revwreimb_state_log_dump","CurrReq"
			WHERE "CurrReq_revwreimb_state_log_dump"."session_id" = "curr_session_id"
			AND "CurrReq"."rid"="CurrReq_revwreimb_state_log_dump"."rid");


--2. "Duplicate" data from the tables that are not in the DEL and ADD lists
	INSERT INTO "Accepted_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Accepted_state_log" WHERE "state"="_state");
	INSERT INTO "Pending_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Pending_state_log" WHERE "state"="_state");
	INSERT INTO "Rejected_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Rejected_state_log" WHERE "state"="_state");
	INSERT INTO "TrvlCost_state_log" ("state","rid","fid") (SELECT "curr_state"+1,"rid","fid" FROM "TrvlCost_state_log" WHERE "state"="_state");	
	INSERT INTO "TrvlMaxAmnt_state_log" ("state","rid","fid") (SELECT "curr_state"+1,"rid","fid" FROM "TrvlMaxAmnt_state_log" WHERE "state"="_state");


		INSERT INTO "states" select 
			"curr_state"+1, 
			hash_accepted_new,
			hash_pending_new,
			hash_rejected_new,
			hash_trvlcost_new,
			hash_trvlmaxamnt_new,
			hash_currreq_new; --add the state to the table of states
		UPDATE "current_state" SET "state"="state"+1; --increment the global state counter
	END IF;

	--4. If TS generation is enabled, add an edge given state analysis
	SELECT "enabled" FROM "TS_enabled" INTO ts_flag;
	IF "ts_flag" = TRUE THEN
		--4.a. collision state coinsides with a state that has been already created before (including loops)
		IF "collision_state"!="_state" and "collision_state">0 THEN
			-- just for debugging 
			UPDATE states_metadata SET recycled_states=recycled_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES ("_state","collision_state",'revwreimb',param_rid);
		END IF;
		--4.b. this state has not been generated yet
		IF "collision_state"=0 THEN
			-- just for debugging 
			UPDATE states_metadata SET unique_states=unique_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES (_state,curr_state+1,'revwreimb',param_rid); --insert a transition
		END IF;
	END IF;


	
END;$$;


ALTER FUNCTION public.revwreimb_eff_exec(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: rvwreq_ca_eval(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rvwreq_ca_eval(_state integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	IF NOT EXISTS 
	(SELECT "state" FROM "rvwreq_params" WHERE "state"="_state")
	THEN
	INSERT INTO "rvwreq_params" ("state", "empl", "dest", "id_currreq", "checked")
		(
		SELECT 
			"_state", 
			"CurrReq"."empl",
			"CurrReq"."dest",
			"CurrReq_state_log"."id",
			FALSE
		FROM "CurrReq", "CurrReq_state_log"
		WHERE "CurrReq_state_log"."state"=_state 
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "status"='submttd'
		);
	END IF;
	--UPDATE "rvwreq_params" SET "executable"=TRUE;
END$$;


ALTER FUNCTION public.rvwreq_ca_eval(_state integer) OWNER TO postgres;

--
-- Name: rvwreq_eff_eval(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rvwreq_eff_eval(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_session_id INTEGER;
BEGIN
	UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";

	-- create and partially fill the table for a service call "status"
	INSERT INTO rvwreq_status_service (session_id,service_name,value)
		(
			SELECT 
			"curr_session_id",
			'status('||"rvwreq_params"."empl"||','||"rvwreq_params"."dest"||')',
			NULL
			FROM "rvwreq_params"
			WHERE "rvwreq_params"."param_id"="param_rid"
		);

	-- create and partially fill the table for a service call "maxAmnt"
	INSERT INTO rvwreq_maxamnt_service (session_id,service_name,value)
		(
			SELECT
			"curr_session_id",
			'maxamnt('||"rvwreq_params"."empl"||','||"rvwreq_params"."dest"||')',
			NULL
			FROM "rvwreq_params"
			WHERE "rvwreq_params"."param_id"="param_rid"
		);

	 --5. Mark used action parameters as checked
	UPDATE "rvwreq_params" SET "checked"=TRUE 
	WHERE "rvwreq_params"."param_id" = "param_rid"
	AND "rvwreq_params"."state" = "_state";
END$$;


ALTER FUNCTION public.rvwreq_eff_eval(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: rvwreq_eff_exec(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION rvwreq_eff_exec(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_state INTEGER; --current state
	curr_session_id INTEGER;
	hash_Accepted_new UUID;
	hash_Pending_new UUID;
	hash_Rejected_new UUID;
	hash_TrvlCost_new UUID;
	hash_TrvlMaxAmnt_new UUID;
	hash_CurrReq_new UUID;
	collision_state INTEGER;
	collision_Accepted INTEGER := 0;
	collision_Pending INTEGER := 0;
	collision_Rejected INTEGER := 0;
	collision_TrvlCost INTEGER := 0;
	collision_TrvlMaxAmnt INTEGER := 0;
	collision_CurrReq INTEGER := 0;
	TS_flag BOOLEAN; 
BEGIN
	SELECT "current_state"."state" FROM "current_state" INTO "curr_state"; --take the current state
	--UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	
	--1. Insert data defined in the ADD list using temporary tables [action]_eff[_i]_eval generated at the effect evaluation stage
	

	INSERT INTO "CurrReq_rvwreq_dump" ("empl", "dest", "status", "phash", "id", "session_id" )
	(SELECT "rvwreq_params"."empl", 
			"rvwreq_params"."dest", 
			"rvwreq_status_service"."value", 
			md5(row("rvwreq_params"."empl", "rvwreq_params"."dest", "rvwreq_status_service"."value", "rvwreq_params"."id_currreq" )::TEXT)::uuid,
			"rvwreq_params"."id_currreq", 
			"curr_session_id"
		FROM "rvwreq_params", "rvwreq_status_service" 
		WHERE "rvwreq_params"."param_id" = "param_rid"
		AND "rvwreq_status_service"."service_name"= 'status('||"rvwreq_params"."empl"||','||"rvwreq_params"."dest"||')' 
		AND "rvwreq_status_service"."session_id"="curr_session_id");

	-- copy all the rest that has not been affected by ADD (or UPDATE)
	INSERT INTO "CurrReq_rvwreq_state_log_dump" ("session_id","rid","id")
	(SELECT "curr_session_id", "CurrReq_state_log"."rid", "CurrReq_state_log"."id"
		FROM "CurrReq_state_log","CurrReq", "rvwreq_params"
		WHERE "CurrReq_state_log"."state"=_state
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "rvwreq_params"."param_id" = "param_rid"
		AND "CurrReq_state_log"."id"<>"rvwreq_params"."id_currreq");

	
	INSERT INTO "TrvlMaxAmnt_rvwreq_dump" ("maxAmnt", "phash", "fid", "session_id")
	(SELECT "rvwreq_maxamnt_service"."value", 
			md5(row("rvwreq_maxamnt_service"."value", "rvwreq_params"."id_currreq")::TEXT)::uuid ,
			"rvwreq_params"."id_currreq",
			"curr_session_id"
	FROM "rvwreq_params", "rvwreq_maxamnt_service"
	WHERE "rvwreq_maxamnt_service"."service_name"= 'maxamnt('||"rvwreq_params"."empl"||','||"rvwreq_params"."dest"||')'
	AND "rvwreq_params"."param_id"="param_rid"
	AND "rvwreq_maxamnt_service"."session_id"="curr_session_id");

	
	-- copy all the rest that has not been affected by ADD (or UPDATE)
	INSERT INTO "TrvlMaxAmnt_rvwreq_state_log_dump" ("session_id","rid","fid")
	(SELECT "curr_session_id", "TrvlMaxAmnt_state_log"."rid", "TrvlMaxAmnt_state_log"."fid"
		FROM "TrvlMaxAmnt_state_log", "TrvlMaxAmnt", "rvwreq_params"
		WHERE "TrvlMaxAmnt_state_log"."state" = _state
		AND "TrvlMaxAmnt_state_log"."rid" = "TrvlMaxAmnt"."rid"
		AND "rvwreq_params"."param_id" = "param_rid"
		AND "TrvlMaxAmnt_state_log"."fid"<>"rvwreq_params"."id_currreq");

	--INSERT INTO "TrvlMaxAmnt"("id", "maxAmnt","rid") (SELECT "rvwreq_params"."id", "rvwreq_maxamnt_service"."value", "rvwreq_params"."rid" FROM "rvwreq_params", "rvwreq_maxamnt_service" WHERE "rvwreq_maxamnt_service"."service_name"= 'maxAmnt('||"rvwreq_params"."empl"||','||"rvwreq_params"."dest"||')' AND "rvwreq_params"."rid"="param_rid" AND "rvwreq_params"."state"="_state");


	--3. Calculate state hash for each table, insert it into states (if at least one hash value is unique) and add a new (curr,next) pair to the TS table
	--3.1. Prepare hash values for the untouched data (i.e., we can use the current state)

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Accepted", "Accepted_state_log" 
	WHERE "state"=_state 
	AND "Accepted"."rid"="Accepted_state_log"."rid" 
	ORDER BY "Accepted_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_accepted_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Pending", "Pending_state_log" 
	WHERE "state"=_state 
	AND "Pending"."rid"="Pending_state_log"."rid" 
	ORDER BY "Pending_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_pending_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Rejected", "Rejected_state_log" 
	WHERE "state"=_state 
	AND "Rejected"."rid"="Rejected_state_log"."rid" 
	ORDER BY "Rejected_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_rejected_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlCost", "TrvlCost_state_log" 
	WHERE "state"=_state 
	AND "TrvlCost"."rid"="TrvlCost_state_log"."rid" 
	ORDER BY "TrvlCost_state_log"."fid" ASC)::TEXT)::uuid
	INTO hash_trvlcost_new;


	SELECT 
		md5(ARRAY(
				SELECT res.phash FROM 
				(SELECT "CurrReq_rvwreq_dump"."id",  "CurrReq_rvwreq_dump"."phash" --take hash of entries in tmp table
					FROM "CurrReq_rvwreq_dump" 
					WHERE "CurrReq_rvwreq_dump"."session_id" = "curr_session_id" 
					UNION
				SELECT "CurrReq"."id", "CurrReq"."phash" --take hash of entries in the original table using tmp temporal portrait (only copied historical values)
					FROM "CurrReq", "CurrReq_rvwreq_state_log_dump" 
					WHERE "CurrReq"."rid"="CurrReq_rvwreq_state_log_dump"."rid" 
					AND "CurrReq_rvwreq_state_log_dump"."session_id" = "curr_session_id" 
				ORDER BY "id" ASC) AS res)::TEXT)::uuid
	INTO hash_currreq_new;


	SELECT 
		md5(ARRAY(
				SELECT res.phash FROM 
				(SELECT "TrvlMaxAmnt_rvwreq_dump"."fid", "TrvlMaxAmnt_rvwreq_dump"."phash" --take hash of entries in the temporary table
					FROM "TrvlMaxAmnt_rvwreq_dump" 
					WHERE "TrvlMaxAmnt_rvwreq_dump"."session_id" = "curr_session_id" 
					UNION
				SELECT "TrvlMaxAmnt"."fid", "TrvlMaxAmnt"."phash" --take hash of entries in the original table using a corresponding temporary temporal portrait (only copied historical values)
					FROM "TrvlMaxAmnt", "TrvlMaxAmnt_rvwreq_state_log_dump" 
					WHERE "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_rvwreq_state_log_dump"."rid" 
					AND "TrvlMaxAmnt_rvwreq_state_log_dump"."session_id" = "curr_session_id" 
				ORDER BY "fid" ASC) AS res)::TEXT)::uuid
	INTO hash_trvlmaxamnt_new;


	--3.2. Check if a tuple compiled out of new hash values can have collisions by confirming that there are no states with exactly the same hash values
	SELECT COALESCE(MAX("state"),0) FROM "states" 
	WHERE "states"."hash_Accepted"=hash_accepted_new
	AND "states"."hash_Pending"=hash_pending_new
	AND "states"."hash_Rejected"=hash_rejected_new
	AND "states"."hash_TrvlCost"=hash_trvlcost_new
	AND "states"."hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "states"."hash_CurrReq"=hash_currreq_new
	INTO "collision_state"; --assume that the first state has a value 1

	-- just for debugging 
	UPDATE states_metadata SET collisions_count=
	collisions_count +
	(SELECT COALESCE(COUNT("state"),0) FROM "states" 
	WHERE "states"."hash_Accepted"=hash_accepted_new
	AND "states"."hash_Pending"=hash_pending_new
	AND "states"."hash_Rejected"=hash_rejected_new
	AND "states"."hash_TrvlCost"=hash_trvlcost_new
	AND "states"."hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "states"."hash_CurrReq"=hash_currreq_new);

	-- just for debugging
	IF "collision_state"<>0 THEN
		SELECT COUNT(1) FROM (
		SELECT * FROM accepted_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM accepted_state_view("collision_state") AS t2) AS res INTO collision_Accepted;

		SELECT COUNT(1) FROM (
		SELECT * FROM pending_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM pending_state_view("collision_state") AS t2) AS res INTO collision_Pending;

		SELECT COUNT(1) FROM (
		SELECT * FROM rejected_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM rejected_state_view("collision_state") AS t2) AS res INTO collision_Rejected;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlcost_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlcost_state_view("collision_state") AS t2) AS res INTO collision_TrvlCost;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlmaxamnt_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlmaxamnt_state_view("collision_state") AS t2) AS res INTO collision_TrvlMaxAmnt;

		SELECT COUNT(1) FROM (
		SELECT * FROM currreq_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM currreq_state_view("collision_state") AS t2) AS res INTO collision_CurrReq;

		-- just for debugging
		IF (collision_CurrReq + 
			collision_TrvlMaxAmnt + 
			collision_TrvlCost + 
			collision_Rejected + 
			collision_Pending + 
			collision_Accepted=0) THEN
			"collision_state":=0;
			UPDATE states_metadata SET deepcheck_success=deepcheck_success+1;
		END IF;
	END IF;

	--3.3. If a state has not been generated yet (i.e., collision_state=0), add it to the states table 
	IF "collision_state"=0 THEN

	-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "CurrReq"("empl", "dest", "status", "id", "rid", "phash") 
		(SELECT "empl", "dest", "status", "id", "rid", "phash" FROM "CurrReq_rvwreq_dump" 
			WHERE "CurrReq_rvwreq_dump"."session_id" = "curr_session_id"
			AND NOT EXISTS 
			(SELECT 1 FROM "CurrReq" 
			WHERE "CurrReq"."phash"="CurrReq_rvwreq_dump"."phash"));

		-- now, for each NEW added data create a corresponding entry in the temporal portrait of CurrReq (i.e., CurrReq_state_log)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM "CurrReq","CurrReq_rvwreq_dump" 
		WHERE "CurrReq"."phash"="CurrReq_rvwreq_dump"."phash"
		AND "CurrReq_rvwreq_dump"."session_id" = "curr_session_id"
		--AND "CurrReq"."rid"="CurrReq_rvwreq_dump"."rid"
		);

		-- now, copy all the data of CurrReq that has not been changed (i.e., the one we put in CurrReq_state_log_tmp)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM  "CurrReq_rvwreq_state_log_dump","CurrReq"
			WHERE "CurrReq_rvwreq_state_log_dump"."session_id" = "curr_session_id"
			AND "CurrReq"."rid"="CurrReq_rvwreq_state_log_dump"."rid");


		-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "TrvlMaxAmnt"("maxAmnt","fid","rid","phash") 
		(SELECT "maxAmnt","fid","rid","phash" FROM "TrvlMaxAmnt_rvwreq_dump" 
			WHERE "TrvlMaxAmnt_rvwreq_dump"."session_id" = "curr_session_id"
			AND NOT EXISTS 
			(SELECT 1 FROM "TrvlMaxAmnt" 
			WHERE "TrvlMaxAmnt"."phash"="TrvlMaxAmnt_rvwreq_dump"."phash"));

		-- now, for each NEW added data create a corresponding entry in the temporal portrait of CurrReq (i.e., CurrReq_state_log)
		INSERT INTO "TrvlMaxAmnt_state_log" ("state", "rid", "fid")
		(SELECT curr_state+1, "TrvlMaxAmnt"."rid", "TrvlMaxAmnt"."fid" FROM "TrvlMaxAmnt","TrvlMaxAmnt_rvwreq_dump"
		WHERE "TrvlMaxAmnt"."phash"="TrvlMaxAmnt_rvwreq_dump"."phash"
		AND "TrvlMaxAmnt_rvwreq_dump"."session_id" = "curr_session_id"
		--AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_rvwreq_dump"."rid"
		);

		-- now, copy all the data of CurrReq that has not been changed (i.e., the one we put in CurrReq_state_log_tmp)
		INSERT INTO "TrvlMaxAmnt_state_log" ("state", "rid", "fid")
		(SELECT curr_state+1, "TrvlMaxAmnt"."rid", "TrvlMaxAmnt"."fid" FROM "TrvlMaxAmnt_rvwreq_state_log_dump","TrvlMaxAmnt"
			WHERE "TrvlMaxAmnt_rvwreq_state_log_dump"."session_id" = "curr_session_id"
			AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_rvwreq_state_log_dump"."rid");



	--2. "Duplicate" data from the tables that are not in the DEL and ADD lists
	INSERT INTO "Accepted_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Accepted_state_log" WHERE "state"="_state");
	INSERT INTO "Pending_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Pending_state_log" WHERE "state"="_state");
	INSERT INTO "Rejected_state_log" ("state","rid","id") (SELECT "curr_state"+1,"rid","id" FROM "Rejected_state_log" WHERE "state"="_state");
	INSERT INTO "TrvlCost_state_log" ("state","rid","fid") (SELECT "curr_state"+1,"rid","fid" FROM "TrvlCost_state_log" WHERE "state"="_state");

		--create a new state
		INSERT INTO "states" select 
			"curr_state"+1, 
			hash_accepted_new,
			hash_pending_new,
			hash_rejected_new,
			hash_trvlcost_new,
			hash_trvlmaxamnt_new,
			hash_currreq_new; --add the state to the table of states
		UPDATE "current_state" SET "state"="state"+1; --increment the global state counter
	END IF;

	--4. If TS generation is enabled, add an edge given state analysis
	SELECT "enabled" FROM "TS_enabled" INTO ts_flag;
	IF "ts_flag" = TRUE THEN
		--4.a. collision state coinsides with a state that has been already created before (including loops)
		IF "collision_state"!="_state" and "collision_state">0 THEN
			-- just for debugging 
			UPDATE states_metadata SET recycled_states=recycled_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES ("_state","collision_state",'rvwreq',param_rid);
		END IF;
		--4.b. this state has not been generated yet
		IF "collision_state"=0 THEN
			-- just for debugging 
			UPDATE states_metadata SET unique_states=unique_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES (_state,curr_state+1,'rvwreq',param_rid); --insert a transition
		END IF;
	END IF;



END;$$;


ALTER FUNCTION public.rvwreq_eff_exec(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: startw_ca_eval(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION startw_ca_eval(_state integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN 
	IF NOT EXISTS 
	(SELECT "state" FROM "startw_params" WHERE "state"="_state")
	THEN
	INSERT INTO "startw_params" ("state", "empl", "dest", "checked", "pending_id")
		(
		SELECT 
			"_state", 
			"Pending"."empl",
			"Pending"."dest",
			FALSE,
			"Pending_state_log"."id"
		FROM "Pending", "Pending_state_log"
		WHERE "Pending_state_log"."state"=_state 
		AND "Pending"."rid"="Pending_state_log"."rid"
		);
	END IF;
END$$;


ALTER FUNCTION public.startw_ca_eval(_state integer) OWNER TO postgres;

--
-- Name: startw_eff_eval(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION startw_eff_eval(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
--5. Mark used action parameters as checked
	UPDATE "startw_params" SET "checked"=TRUE 
	WHERE "startw_params"."param_id" = "param_rid";
END$$;


ALTER FUNCTION public.startw_eff_eval(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: startw_eff_exec(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION startw_eff_exec(_state integer, param_rid integer) RETURNS void
    LANGUAGE plpgsql
    AS $$DECLARE 
	curr_state INTEGER; --current state
	curr_session_id INTEGER;
	hash_Accepted_new uuid;
	hash_Pending_new uuid;
	hash_Rejected_new uuid;
	hash_TrvlCost_new uuid;
	hash_TrvlMaxAmnt_new uuid;
	hash_CurrReq_new uuid;
	hash_CurrReq_insert uuid;
	collision_state INTEGER;
	collision_Accepted INTEGER := 0;
	collision_Pending INTEGER := 0;
	collision_Rejected INTEGER := 0;
	collision_TrvlCost INTEGER := 0;
	collision_TrvlMaxAmnt INTEGER := 0;
	collision_CurrReq INTEGER := 0;
	TS_flag BOOLEAN;	
BEGIN

	--SET CONSTRAINTS ALL DEFERRED;

	SELECT "current_state"."state" FROM "current_state" INTO "curr_state"; --take the current state
	UPDATE "current_session_id" SET "session"="session"+1; --increment the global session id
	SELECT "current_session_id"."session" FROM "current_session_id" INTO "curr_session_id";
	--0. Given relations appearing the DEL list, "copy" their previous state entries which were not meant to be deleted

	INSERT INTO "Pending_startw_state_log_dump" ("session_id","rid","id")
	(SELECT "curr_session_id", "Pending_state_log"."rid", "Pending_state_log"."id"
		FROM  "startw_params","Pending", "Pending_state_log"
		WHERE "Pending_state_log"."state"= _state
		AND "Pending"."rid"="Pending_state_log"."rid"
		AND "startw_params"."param_id" = "param_rid"
		AND "Pending_state_log"."id"<>"startw_params"."pending_id");

	--1. Insert data defined in the ADD list using temporary tables [action]_eff[_i]_eval generated at the effect evaluation stage

	INSERT INTO "CurrReq_startw_dump" ("empl", "dest", "status", "phash", "id", "session_id" )
	(SELECT "startw_params"."empl", 
			"startw_params"."dest", 
			'submttd', 
			md5(row("startw_params"."empl", "startw_params"."dest", 'submttd', "startw_params"."pending_id" )::TEXT)::uuid,
			"startw_params"."pending_id", 
			"curr_session_id"
		FROM "startw_params" 
		WHERE "startw_params"."param_id" = "param_rid");


-- copy all the rest that has not been affected by ADD (or UPDATE)

	INSERT INTO "CurrReq_startw_state_log_dump" ("session_id","rid","id")
	(SELECT "curr_session_id", "CurrReq_state_log"."rid", "CurrReq_state_log"."id"
		FROM "CurrReq_state_log","CurrReq", "startw_params"
		WHERE "CurrReq_state_log"."state"=_state
		AND "CurrReq"."rid"="CurrReq_state_log"."rid"
		AND "startw_params"."param_id" = "param_rid"
		AND "CurrReq_state_log"."id"<>"startw_params"."pending_id");


	--3. Calculate state hash for each table, insert it into states (if at least one hash value is unique) and add a new (curr,next) pair to the TS table
	--3.1. Prepare hash values for the untouched data (i.e., we can use the current state)


	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Accepted", "Accepted_state_log" 
	WHERE "state"=_state 
	AND "Accepted"."rid"="Accepted_state_log"."rid" 
	ORDER BY "Accepted_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_accepted_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Rejected", "Rejected_state_log" 
	WHERE "state"=_state 
	AND "Rejected"."rid"="Rejected_state_log"."rid" 
	ORDER BY "Rejected_state_log"."id" ASC)::TEXT)::uuid
	INTO hash_rejected_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlCost", "TrvlCost_state_log" 
	WHERE "state"=_state 
	AND "TrvlCost"."rid"="TrvlCost_state_log"."rid" 
	ORDER BY "TrvlCost_state_log"."fid" ASC)::TEXT)::uuid
	INTO hash_trvlcost_new;

	SELECT md5(ARRAY(SELECT "phash" 
	FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log" 
	WHERE "state"=_state 
	AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid" 
	ORDER BY "TrvlMaxAmnt_state_log"."fid" ASC)::TEXT)::uuid 
	INTO hash_trvlmaxamnt_new;


	--generate hashes for the relations that have been only temporally affected
	SELECT md5(ARRAY(SELECT "phash" 
	FROM "Pending", "Pending_startw_state_log_dump" 
	WHERE "Pending"."rid"="Pending_startw_state_log_dump"."rid" 
	AND "Pending_startw_state_log_dump"."session_id" = "curr_session_id" 
	ORDER BY "Pending_startw_state_log_dump"."id" ASC)::TEXT)::uuid INTO hash_pending_new;
	--generate hashes in a special way only for those relations which have been also non-temporally updated
	SELECT 
		md5(ARRAY(
				SELECT res.phash FROM 
				(SELECT "CurrReq_startw_dump"."id", "CurrReq_startw_dump"."phash" --take hash of entries in tmp table
					FROM "CurrReq_startw_dump" 
					WHERE "CurrReq_startw_dump"."session_id" = "curr_session_id" 
				UNION
				SELECT "CurrReq"."id", "CurrReq"."phash" --take hash of entries in the original table using tmp temporal portrait (only copied historical values)
					FROM "CurrReq", "CurrReq_startw_state_log_dump" 
					WHERE "CurrReq"."rid"="CurrReq_startw_state_log_dump"."rid" 
					AND "CurrReq_startw_state_log_dump"."session_id" = "curr_session_id" 
				ORDER BY id ASC) AS res)::TEXT)::uuid
	INTO hash_currreq_new;


	--3.2. Check if a tuple compiled out of new hash values can have collisions by conferming that there are no states with exactly the same hash values
	SELECT COALESCE(MAX("state"),0) FROM "states" 
	WHERE "states"."hash_Accepted"=hash_accepted_new
	AND "states"."hash_Pending"=hash_pending_new
	AND "states"."hash_Rejected"=hash_rejected_new
	AND "states"."hash_TrvlCost"=hash_trvlcost_new
	AND "states"."hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "states"."hash_CurrReq"=hash_currreq_new
	INTO "collision_state"; --assume that the first state has a value 1

	-- just for debugging 
	UPDATE states_metadata SET collisions_count=
	collisions_count +
	(SELECT COALESCE(COUNT("state"),0) FROM "states" 
	WHERE "states"."hash_Accepted"=hash_accepted_new
	AND "states"."hash_Pending"=hash_pending_new
	AND "states"."hash_Rejected"=hash_rejected_new
	AND "states"."hash_TrvlCost"=hash_trvlcost_new
	AND "states"."hash_TrvlMaxAmnt"=hash_trvlmaxamnt_new
	AND "states"."hash_CurrReq"=hash_currreq_new);


	-- just for debugging
	IF "collision_state"<>0 THEN
		SELECT COUNT(1) FROM (
		SELECT * FROM accepted_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM accepted_state_view("collision_state") AS t2) AS res INTO collision_Accepted;

		SELECT COUNT(1) FROM (
		SELECT * FROM pending_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM pending_state_view("collision_state") AS t2) AS res INTO collision_Pending;

		SELECT COUNT(1) FROM (
		SELECT * FROM rejected_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM rejected_state_view("collision_state") AS t2) AS res INTO collision_Rejected;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlcost_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlcost_state_view("collision_state") AS t2) AS res INTO collision_TrvlCost;

		SELECT COUNT(1) FROM (
		SELECT * FROM trvlmaxamnt_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM trvlmaxamnt_state_view("collision_state") AS t2) AS res INTO collision_TrvlMaxAmnt;

		SELECT COUNT(1) FROM (
		SELECT * FROM currreq_state_view("_state") AS t1
		EXCEPT 
		SELECT * FROM currreq_state_view("collision_state") AS t2) AS res INTO collision_CurrReq;

		-- just for debugging
		IF (collision_CurrReq + 
			collision_TrvlMaxAmnt + 
			collision_TrvlCost + 
			collision_Rejected + 
			collision_Pending + 
			collision_Accepted=0) THEN
			"collision_state":=0;
			UPDATE states_metadata SET deepcheck_success=deepcheck_success+1;
		END IF;
	END IF;

	--3.3. If a state has not been generated yet (i.e., collision_state=0), add it to the states table 
	IF "collision_state"=0 THEN
	-- insert all the data from the temporary tables into original tables
		INSERT INTO "Pending_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "rid", "id"
		FROM "Pending_startw_state_log_dump"
		WHERE "Pending_startw_state_log_dump"."session_id" = "curr_session_id");
	
		-- here we need to check, whether per entry everything is fine and we can add data with non-existing hash to the table
		INSERT INTO "CurrReq"("empl", "dest", "status", "id", "rid", "phash") 
		(SELECT "empl", "dest", "status", "id", "rid", "phash" FROM "CurrReq_startw_dump" 
			WHERE "CurrReq_startw_dump"."session_id" = "curr_session_id"
			AND NOT EXISTS 
			(SELECT 1 FROM "CurrReq" 
			WHERE "CurrReq"."phash"="CurrReq_startw_dump"."phash"));

		-- now, for each NEW added data create a corresponding entry in the temporal portrait of CurrReq (i.e., CurrReq_state_log)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM "CurrReq","CurrReq_startw_dump"
		WHERE "CurrReq"."phash"="CurrReq_startw_dump"."phash"
		AND "CurrReq_startw_dump"."session_id" = "curr_session_id"
		--AND "CurrReq"."rid"="CurrReq_startw_dump"."rid"
		);

		-- now, copy all the data of CurrReq that has not been changed (i.e., the one we put in CurrReq_state_log_tmp)
		INSERT INTO "CurrReq_state_log" ("state", "rid", "id")
		(SELECT curr_state+1, "CurrReq"."rid", "CurrReq"."id" FROM  "CurrReq_startw_state_log_dump","CurrReq"
			WHERE "CurrReq_startw_state_log_dump"."session_id" = "curr_session_id"
			AND "CurrReq"."rid"="CurrReq_startw_state_log_dump"."rid");

	--2. "Duplicate" data from the tables that are not in the DEL and ADD lists
	
	INSERT INTO "Accepted_state_log" ("state","rid","id") (SELECT "curr_state"+1, "rid", "id" FROM "Accepted_state_log" WHERE "state"="_state");
	INSERT INTO "Rejected_state_log" ("state","rid","id") (SELECT "curr_state"+1, "rid", "id" FROM "Rejected_state_log" WHERE "state"="_state");
	INSERT INTO "TrvlMaxAmnt_state_log" ("state","rid","fid") (SELECT "curr_state"+1, "rid", "fid" FROM "TrvlMaxAmnt_state_log" WHERE "state"="_state");
	INSERT INTO "TrvlCost_state_log" ("state","rid","fid") (SELECT "curr_state"+1, "rid", "fid" FROM "TrvlCost_state_log" WHERE "state"="_state");



	--create a new state
		INSERT INTO "states" select 
			"curr_state"+1, 
			hash_accepted_new,
			hash_pending_new,
			hash_rejected_new,
			hash_trvlcost_new,
			hash_trvlmaxamnt_new,
			hash_currreq_new; --add the state to the table of states
		UPDATE "current_state" SET "state"="state"+1; --increment the global state counter
	END IF;

	--4. If TS generation is enabled, add an edge given state analysis
	SELECT "enabled" FROM "TS_enabled" INTO ts_flag;
	IF ts_flag = TRUE THEN
		--4.a. collision state coinsides with a state that has been already created before (including loops)
		IF "collision_state"!="_state" and "collision_state">0 THEN
			-- just for debugging 
			UPDATE states_metadata SET recycled_states=recycled_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES ("_state","collision_state",'startw',param_rid);
		END IF;
		--4.b. this state has not been generated yet
		IF "collision_state"=0 THEN
			-- just for debugging 
			UPDATE states_metadata SET unique_states=unique_states+1;
			INSERT INTO "TS" ("curr","next","action","binding") VALUES (_state,curr_state+1,'startw',param_rid); --insert a transition
		END IF;
	END IF;

 
END;$$;


ALTER FUNCTION public.startw_eff_exec(_state integer, param_rid integer) OWNER TO postgres;

--
-- Name: trvlcost_state_map(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION trvlcost_state_map(_state integer) RETURNS TABLE(fid integer, cost integer, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "TrvlCost_state_log"."fid", "TrvlCost"."cost", "TrvlCost_state_log"."rid"
		FROM "TrvlCost", "TrvlCost_state_log"  
		WHERE "state"=_state AND "TrvlCost"."rid"="TrvlCost_state_log"."rid";
END$$;


ALTER FUNCTION public.trvlcost_state_map(_state integer) OWNER TO postgres;

--
-- Name: trvlcost_state_map_until(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION trvlcost_state_map_until(_state integer) RETURNS TABLE(id integer, fid integer, cost integer, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "TrvlCost_state_log"."id", "TrvlCost_state_log"."fid", "TrvlCost"."cost", "TrvlCost_state_log"."rid"
		FROM "TrvlCost", "TrvlCost_state_log"  
		WHERE "state"<_state AND "state">1 AND "TrvlCost"."rid"="TrvlCost_state_log"."rid";
END$$;


ALTER FUNCTION public.trvlcost_state_map_until(_state integer) OWNER TO postgres;

--
-- Name: trvlcost_state_view(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION trvlcost_state_view(_state integer) RETURNS TABLE(fid integer, cost integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "TrvlCost_state_log"."fid", "TrvlCost"."cost"
		FROM "TrvlCost", "TrvlCost_state_log"  
		WHERE "state"=_state AND "TrvlCost"."rid"="TrvlCost_state_log"."rid"
		ORDER BY "TrvlCost_state_log"."fid" ASC;
END$$;


ALTER FUNCTION public.trvlcost_state_view(_state integer) OWNER TO postgres;

--
-- Name: trvlmaxamnt_state_map(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION trvlmaxamnt_state_map(_state integer) RETURNS TABLE(fid integer, maxamnt integer, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "TrvlMaxAmnt_state_log"."fid","TrvlMaxAmnt"."maxAmnt", "TrvlMaxAmnt_state_log"."rid"
		FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log"  
		WHERE "state"=_state AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid";
END$$;


ALTER FUNCTION public.trvlmaxamnt_state_map(_state integer) OWNER TO postgres;

--
-- Name: trvlmaxamnt_state_map_until(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION trvlmaxamnt_state_map_until(_state integer) RETURNS TABLE(id integer, fid integer, maxamnt integer, rid integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "TrvlMaxAmnt_state_log"."id", "TrvlMaxAmnt_state_log"."fid","TrvlMaxAmnt"."maxAmnt", "TrvlMaxAmnt_state_log"."rid"
		FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log"  
		WHERE "state"<_state AND "state">1 AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid";
END$$;


ALTER FUNCTION public.trvlmaxamnt_state_map_until(_state integer) OWNER TO postgres;

--
-- Name: trvlmaxamnt_state_view(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION trvlmaxamnt_state_view(_state integer) RETURNS TABLE(fid integer, maxamnt integer)
    LANGUAGE plpgsql IMMUTABLE
    AS $$BEGIN
	RETURN QUERY 
		SELECT "TrvlMaxAmnt_state_log"."fid","TrvlMaxAmnt"."maxAmnt"
		FROM "TrvlMaxAmnt", "TrvlMaxAmnt_state_log"  
		WHERE "state"=_state AND "TrvlMaxAmnt"."rid"="TrvlMaxAmnt_state_log"."rid"
		ORDER BY "TrvlMaxAmnt_state_log"."fid" ASC;
END$$;


ALTER FUNCTION public.trvlmaxamnt_state_view(_state integer) OWNER TO postgres;

--
-- Name: update_accepted_state_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_accepted_state_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;

	IF (NOT EXISTS 
			(SELECT 1 
			FROM "Accepted_state_log" 
			WHERE "Accepted_state_log"."state"=new_state 
			AND "Accepted_state_log"."rid"=NEW."rid"))
	THEN
		INSERT INTO "Accepted_state_log" ("state","rid","id") 
		VALUES (new_state, NEW."rid", NEW."id");
	END IF;
	RETURN NEW;
END $$;


ALTER FUNCTION public.update_accepted_state_log() OWNER TO postgres;

--
-- Name: update_currreq_state_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_currreq_state_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	-- if we have not inserted anything yet with a new state in the log,
	-- then update this log using an ID of a fresh entry
	IF (NOT EXISTS 
			(SELECT 1 
			FROM "CurrReq_state_log" 
			WHERE "CurrReq_state_log"."state"=new_state 
			AND "CurrReq_state_log"."id"=NEW.id))
	THEN
		INSERT INTO "CurrReq_state_log" ("state","rid","id") 
		VALUES (new_state, NEW."rid", NEW."id");
	END IF;
	RETURN NEW;
END $$;


ALTER FUNCTION public.update_currreq_state_log() OWNER TO postgres;

--
-- Name: update_fillrmb_cost_service(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_fillrmb_cost_service(_signature character varying, _value integer, _session_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	UPDATE "fillrmb_cost_service" SET "value"=_value 
	WHERE "fillrmb_cost_service"."service_name"=_signature
	AND "fillrmb_cost_service"."session_id"=_session_id;
END;$$;


ALTER FUNCTION public.update_fillrmb_cost_service(_signature character varying, _value integer, _session_id integer) OWNER TO postgres;

--
-- Name: update_pending_state_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_pending_state_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;

	IF (NOT EXISTS 
			(SELECT 1 
			FROM "Pending_state_log" 
			WHERE "Pending_state_log"."state"=new_state 
			AND "Pending_state_log"."rid"=NEW."rid"))
	THEN
		INSERT INTO "Pending_state_log" ("state","rid","id") 
		VALUES (new_state, NEW."rid", NEW."id");
	END IF;
	RETURN NEW;
END $$;


ALTER FUNCTION public.update_pending_state_log() OWNER TO postgres;

--
-- Name: update_rejected_state_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_rejected_state_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;
	IF (NOT EXISTS 
			(SELECT 1 
			FROM "Rejected_state_log" 
			WHERE "Rejected_state_log"."state"=new_state 
			AND "Rejected_state_log"."rid"=NEW."rid"))
	THEN
		INSERT INTO "Rejected_state_log" ("state","rid","id") 
		VALUES (new_state, NEW."rid", NEW."id");
	END IF;
	RETURN NEW;
END $$;


ALTER FUNCTION public.update_rejected_state_log() OWNER TO postgres;

--
-- Name: update_rvwreq_maxamnt_service(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_rvwreq_maxamnt_service(_signature character varying, _value integer, _session_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	UPDATE "rvwreq_maxamnt_service" SET "value"=_value 
	WHERE "rvwreq_maxamnt_service"."service_name"=_signature
	AND "rvwreq_maxamnt_service"."session_id"=_session_id;
END;$$;


ALTER FUNCTION public.update_rvwreq_maxamnt_service(_signature character varying, _value integer, _session_id integer) OWNER TO postgres;

--
-- Name: update_rvwreq_status_service(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_rvwreq_status_service(_signature character varying, _value character varying, _session_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$BEGIN
	UPDATE "rvwreq_status_service" SET "value"=_value 
	WHERE "rvwreq_status_service"."service_name"=_signature
	AND "rvwreq_status_service"."session_id"=_session_id;
END;$$;


ALTER FUNCTION public.update_rvwreq_status_service(_signature character varying, _value character varying, _session_id integer) OWNER TO postgres;

--
-- Name: update_trvlcost_state_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_trvlcost_state_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;

	IF (NOT EXISTS 
			(SELECT 1 
			FROM "TrvlCost_state_log" 
			WHERE "TrvlCost_state_log"."state"=new_state 
			AND "TrvlCost_state_log"."rid"=NEW."rid"))
	THEN
		INSERT INTO "TrvlCost_state_log" ("state","rid", "fid") 
		VALUES (new_state, NEW."rid", NEW."fid");
	END IF;
	RETURN NEW;
END $$;


ALTER FUNCTION public.update_trvlcost_state_log() OWNER TO postgres;

--
-- Name: update_trvlmaxamnt_state_log(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION update_trvlmaxamnt_state_log() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE 
	new_state int4;
BEGIN
	SELECT "state"+1 INTO new_state FROM current_state;

	IF (NOT EXISTS 
			(SELECT 1 
			FROM "TrvlMaxAmnt_state_log" 
			WHERE "TrvlMaxAmnt_state_log"."state"=new_state 
			AND "TrvlMaxAmnt_state_log"."rid"=NEW."rid"))
	THEN
		INSERT INTO "TrvlMaxAmnt_state_log" ("state","rid","fid") 
		VALUES (new_state, NEW."rid", NEW."fid");
	END IF;
	RETURN NEW;
END $$;


ALTER FUNCTION public.update_trvlmaxamnt_state_log() OWNER TO postgres;

--
-- Name: id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE id_seq OWNER TO postgres;

--
-- Name: inc_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE inc_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE inc_seq OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Accepted; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Accepted" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    amount integer NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer DEFAULT nextval('id_seq'::regclass) NOT NULL
);


ALTER TABLE "Accepted" OWNER TO postgres;

--
-- Name: Accepted_endw_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Accepted_endw_dump" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    amount integer NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "Accepted_endw_dump" OWNER TO postgres;

--
-- Name: Accepted_endw_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Accepted_endw_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "Accepted_endw_state_log_dump" OWNER TO postgres;

--
-- Name: Accepted_state_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Accepted_state_log" (
    state integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "Accepted_state_log" OWNER TO postgres;

--
-- Name: Accepted_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Accepted_state_log_dump" (
    state integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "Accepted_state_log_dump" OWNER TO postgres;

--
-- Name: CurrReq; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    status character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer DEFAULT nextval('id_seq'::regclass) NOT NULL
);


ALTER TABLE "CurrReq" OWNER TO postgres;

--
-- Name: CurrReq_endw_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_endw_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "CurrReq_endw_state_log_dump" OWNER TO postgres;

--
-- Name: CurrReq_fillrmb_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_fillrmb_dump" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    status character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "CurrReq_fillrmb_dump" OWNER TO postgres;

--
-- Name: CurrReq_fillrmb_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_fillrmb_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "CurrReq_fillrmb_state_log_dump" OWNER TO postgres;

--
-- Name: CurrReq_revwreimb_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_revwreimb_dump" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    status character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "CurrReq_revwreimb_dump" OWNER TO postgres;

--
-- Name: CurrReq_revwreimb_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_revwreimb_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "CurrReq_revwreimb_state_log_dump" OWNER TO postgres;

--
-- Name: CurrReq_rvwreq_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_rvwreq_dump" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    status character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "CurrReq_rvwreq_dump" OWNER TO postgres;

--
-- Name: CurrReq_rvwreq_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_rvwreq_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "CurrReq_rvwreq_state_log_dump" OWNER TO postgres;

--
-- Name: CurrReq_startw_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_startw_dump" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    status character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "CurrReq_startw_dump" OWNER TO postgres;

--
-- Name: CurrReq_startw_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_startw_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "CurrReq_startw_state_log_dump" OWNER TO postgres;

--
-- Name: CurrReq_state_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "CurrReq_state_log" (
    state integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "CurrReq_state_log" OWNER TO postgres;

--
-- Name: Dest; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Dest" (
    id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    dest character varying(40) NOT NULL
);


ALTER TABLE "Dest" OWNER TO postgres;

--
-- Name: Empl; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Empl" (
    id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    empl character varying(40) NOT NULL
);


ALTER TABLE "Empl" OWNER TO postgres;

--
-- Name: Pending; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Pending" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer DEFAULT nextval('id_seq'::regclass) NOT NULL
);


ALTER TABLE "Pending" OWNER TO postgres;

--
-- Name: Pending_startw_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Pending_startw_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "Pending_startw_state_log_dump" OWNER TO postgres;

--
-- Name: Pending_state_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Pending_state_log" (
    state integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "Pending_state_log" OWNER TO postgres;

--
-- Name: Rejected; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Rejected" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer DEFAULT nextval('id_seq'::regclass) NOT NULL
);


ALTER TABLE "Rejected" OWNER TO postgres;

--
-- Name: Rejected_endw_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Rejected_endw_dump" (
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    id integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "Rejected_endw_dump" OWNER TO postgres;

--
-- Name: Rejected_endw_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Rejected_endw_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "Rejected_endw_state_log_dump" OWNER TO postgres;

--
-- Name: Rejected_state_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "Rejected_state_log" (
    state integer NOT NULL,
    rid integer NOT NULL,
    id integer NOT NULL
);


ALTER TABLE "Rejected_state_log" OWNER TO postgres;

--
-- Name: TS; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TS" (
    curr integer NOT NULL,
    next integer NOT NULL,
    action character varying(40) NOT NULL,
    binding integer NOT NULL
);


ALTER TABLE "TS" OWNER TO postgres;

--
-- Name: TS_enabled; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TS_enabled" (
    enabled boolean NOT NULL,
    id smallint DEFAULT 1 NOT NULL
);


ALTER TABLE "TS_enabled" OWNER TO postgres;

--
-- Name: TrvlCost; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlCost" (
    cost integer NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlCost" OWNER TO postgres;

--
-- Name: TrvlCost_endw_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlCost_endw_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlCost_endw_state_log_dump" OWNER TO postgres;

--
-- Name: TrvlCost_fillrmb_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlCost_fillrmb_dump" (
    cost integer NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    fid integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "TrvlCost_fillrmb_dump" OWNER TO postgres;

--
-- Name: TrvlCost_fillrmb_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlCost_fillrmb_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlCost_fillrmb_state_log_dump" OWNER TO postgres;

--
-- Name: TrvlCost_state_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlCost_state_log" (
    state integer NOT NULL,
    rid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlCost_state_log" OWNER TO postgres;

--
-- Name: TrvlMaxAmnt; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlMaxAmnt" (
    "maxAmnt" integer NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlMaxAmnt" OWNER TO postgres;

--
-- Name: TrvlMaxAmnt_endw_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlMaxAmnt_endw_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlMaxAmnt_endw_state_log_dump" OWNER TO postgres;

--
-- Name: TrvlMaxAmnt_rvwreq_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlMaxAmnt_rvwreq_dump" (
    "maxAmnt" integer NOT NULL,
    rid integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    phash uuid NOT NULL,
    fid integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE "TrvlMaxAmnt_rvwreq_dump" OWNER TO postgres;

--
-- Name: TrvlMaxAmnt_rvwreq_state_log_dump; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlMaxAmnt_rvwreq_state_log_dump" (
    session_id integer NOT NULL,
    rid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlMaxAmnt_rvwreq_state_log_dump" OWNER TO postgres;

--
-- Name: TrvlMaxAmnt_state_log; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE "TrvlMaxAmnt_state_log" (
    state integer NOT NULL,
    rid integer NOT NULL,
    fid integer NOT NULL
);


ALTER TABLE "TrvlMaxAmnt_state_log" OWNER TO postgres;

--
-- Name: action_metadata; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE action_metadata (
    id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    action character varying(40) NOT NULL,
    service integer
);


ALTER TABLE action_metadata OWNER TO postgres;

--
-- Name: current_session_id; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE current_session_id (
    id smallint DEFAULT 1 NOT NULL,
    session integer NOT NULL
);


ALTER TABLE current_session_id OWNER TO postgres;

--
-- Name: current_state; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE current_state (
    id smallint DEFAULT 1 NOT NULL,
    state integer NOT NULL
);


ALTER TABLE current_state OWNER TO postgres;

--
-- Name: endw_eff_1_eval_res; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE endw_eff_1_eval_res (
    cost integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE endw_eff_1_eval_res OWNER TO postgres;

--
-- Name: endw_eff_2_eval_res; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE endw_eff_2_eval_res (
    "exists" boolean NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE endw_eff_2_eval_res OWNER TO postgres;

--
-- Name: endw_params; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE endw_params (
    param_id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    state integer NOT NULL,
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    status character varying(40) NOT NULL,
    id_currreq integer NOT NULL,
    checked boolean NOT NULL
);


ALTER TABLE endw_params OWNER TO postgres;

--
-- Name: fillrmb_cost_service; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE fillrmb_cost_service (
    session_id integer NOT NULL,
    service_name character varying(40) NOT NULL,
    value integer
);


ALTER TABLE fillrmb_cost_service OWNER TO postgres;

--
-- Name: fillrmb_params; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE fillrmb_params (
    param_id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    state integer NOT NULL,
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    id_currreq integer NOT NULL,
    checked boolean NOT NULL
);


ALTER TABLE fillrmb_params OWNER TO postgres;

--
-- Name: maxamnt_allowed_values; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE maxamnt_allowed_values (
    value integer NOT NULL
);


ALTER TABLE maxamnt_allowed_values OWNER TO postgres;

--
-- Name: relation_names; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE relation_names (
    name character varying(60) NOT NULL,
    readonly boolean NOT NULL
);


ALTER TABLE relation_names OWNER TO postgres;

--
-- Name: revwreimb_eff_1_eval_res; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE revwreimb_eff_1_eval_res (
    id_currreq integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE revwreimb_eff_1_eval_res OWNER TO postgres;

--
-- Name: revwreimb_eff_2_eval_res; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE revwreimb_eff_2_eval_res (
    id_currreq integer NOT NULL,
    session_id integer NOT NULL
);


ALTER TABLE revwreimb_eff_2_eval_res OWNER TO postgres;

--
-- Name: revwreimb_params; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE revwreimb_params (
    param_id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    state integer NOT NULL,
    cost integer NOT NULL,
    id_currreq integer NOT NULL,
    checked boolean NOT NULL
);


ALTER TABLE revwreimb_params OWNER TO postgres;

--
-- Name: rvwreq_maxamnt_service; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE rvwreq_maxamnt_service (
    session_id integer NOT NULL,
    service_name character varying(40) NOT NULL,
    value integer
);


ALTER TABLE rvwreq_maxamnt_service OWNER TO postgres;

--
-- Name: rvwreq_params; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE rvwreq_params (
    param_id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    state integer NOT NULL,
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    id_currreq integer NOT NULL,
    checked boolean NOT NULL
);


ALTER TABLE rvwreq_params OWNER TO postgres;

--
-- Name: rvwreq_status_service; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE rvwreq_status_service (
    session_id integer NOT NULL,
    service_name character varying(40) NOT NULL,
    value character varying(40)
);


ALTER TABLE rvwreq_status_service OWNER TO postgres;

--
-- Name: service_metadata; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE service_metadata (
    service character varying(60) NOT NULL,
    service_return_type character varying(60) NOT NULL,
    service_fresh_only boolean NOT NULL,
    service_allowed_values_table character varying(60),
    id integer NOT NULL
);


ALTER TABLE service_metadata OWNER TO postgres;

--
-- Name: startw_params; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE startw_params (
    param_id integer DEFAULT nextval('inc_seq'::regclass) NOT NULL,
    state integer NOT NULL,
    empl character varying(40) NOT NULL,
    dest character varying(40) NOT NULL,
    checked boolean NOT NULL,
    pending_id integer NOT NULL
);


ALTER TABLE startw_params OWNER TO postgres;

--
-- Name: states; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE states (
    state integer NOT NULL,
    "hash_Accepted" uuid NOT NULL,
    "hash_Pending" uuid NOT NULL,
    "hash_Rejected" uuid NOT NULL,
    "hash_TrvlCost" uuid NOT NULL,
    "hash_TrvlMaxAmnt" uuid NOT NULL,
    "hash_CurrReq" uuid NOT NULL
);


ALTER TABLE states OWNER TO postgres;

--
-- Name: states_metadata; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE states_metadata (
    unique_states integer NOT NULL,
    recycled_states integer NOT NULL,
    collisions_count integer NOT NULL,
    deepcheck_success integer NOT NULL
);


ALTER TABLE states_metadata OWNER TO postgres;

--
-- Name: status_allowed_values; Type: TABLE; Schema: public; Owner: postgres; Tablespace: 
--

CREATE TABLE status_allowed_values (
    value character varying(40) NOT NULL
);


ALTER TABLE status_allowed_values OWNER TO postgres;

--
-- Data for Name: Accepted; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Accepted" (empl, dest, amount, rid, phash, id) FROM stdin;
Andy	Paris	0	150	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9
Andy	NY	0	205	489def5b-aece-1c21-00b8-22b66d52d6a8	3
Andy	NY	1	468	458bfbdf-1345-6e2f-4d1a-68f472ebdb52	3
\.


--
-- Data for Name: Accepted_endw_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Accepted_endw_dump" (empl, dest, amount, rid, phash, id, session_id) FROM stdin;
Andy	Paris	0	150	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	82
Andy	NY	0	205	489def5b-aece-1c21-00b8-22b66d52d6a8	3	112
Andy	Paris	0	252	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	138
Andy	NY	0	319	489def5b-aece-1c21-00b8-22b66d52d6a8	3	174
Andy	NY	0	332	489def5b-aece-1c21-00b8-22b66d52d6a8	3	181
Andy	Paris	0	339	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	185
Andy	Paris	0	343	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	187
Andy	Paris	0	362	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	197
Andy	Paris	0	366	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	199
Andy	NY	0	422	489def5b-aece-1c21-00b8-22b66d52d6a8	3	228
Andy	NY	0	438	489def5b-aece-1c21-00b8-22b66d52d6a8	3	237
Andy	Paris	0	442	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	239
Andy	Paris	0	454	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	246
Andy	NY	0	460	489def5b-aece-1c21-00b8-22b66d52d6a8	3	249
Andy	Paris	0	464	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	251
Andy	NY	1	468	458bfbdf-1345-6e2f-4d1a-68f472ebdb52	3	253
Andy	Paris	0	472	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	255
Andy	NY	0	485	489def5b-aece-1c21-00b8-22b66d52d6a8	3	262
Andy	NY	0	501	489def5b-aece-1c21-00b8-22b66d52d6a8	3	270
Andy	NY	1	509	458bfbdf-1345-6e2f-4d1a-68f472ebdb52	3	274
Andy	NY	0	526	489def5b-aece-1c21-00b8-22b66d52d6a8	3	283
Andy	NY	0	529	489def5b-aece-1c21-00b8-22b66d52d6a8	3	284
Andy	Paris	0	530	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	285
Andy	NY	0	537	489def5b-aece-1c21-00b8-22b66d52d6a8	3	288
Andy	Paris	0	538	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	289
Andy	NY	1	543	458bfbdf-1345-6e2f-4d1a-68f472ebdb52	3	291
Andy	Paris	0	544	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	292
Andy	NY	0	551	489def5b-aece-1c21-00b8-22b66d52d6a8	3	295
Andy	NY	0	563	489def5b-aece-1c21-00b8-22b66d52d6a8	3	301
Andy	NY	1	569	458bfbdf-1345-6e2f-4d1a-68f472ebdb52	3	304
Andy	Paris	0	576	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	308
Andy	NY	0	578	489def5b-aece-1c21-00b8-22b66d52d6a8	3	309
Andy	NY	0	580	489def5b-aece-1c21-00b8-22b66d52d6a8	3	310
Andy	Paris	0	582	3e5c0d16-5b35-eb6a-134e-cc011a316f40	9	311
Andy	NY	1	584	458bfbdf-1345-6e2f-4d1a-68f472ebdb52	3	312
Andy	NY	0	590	489def5b-aece-1c21-00b8-22b66d52d6a8	3	315
Andy	NY	1	594	458bfbdf-1345-6e2f-4d1a-68f472ebdb52	3	317
\.


--
-- Data for Name: Accepted_endw_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Accepted_endw_state_log_dump" (session_id, rid, id) FROM stdin;
247	150	9
260	150	9
282	205	3
308	205	3
309	150	9
310	150	9
311	468	3
312	150	9
313	205	3
316	468	3
\.


--
-- Data for Name: Accepted_state_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Accepted_state_log" (state, rid, id) FROM stdin;
37	150	9
48	205	3
58	150	9
71	205	3
74	205	3
75	150	9
77	150	9
82	150	9
83	150	9
95	205	3
98	205	3
99	150	9
100	150	9
102	150	9
104	468	3
105	150	9
107	205	3
113	468	3
115	205	3
116	205	3
117	150	9
118	150	9
119	468	3
120	150	9
121	205	3
124	468	3
126	150	9
126	205	3
127	150	9
127	468	3
128	468	3
\.


--
-- Data for Name: Accepted_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Accepted_state_log_dump" (state, rid, id) FROM stdin;
\.


--
-- Data for Name: CurrReq; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq" (empl, dest, status, rid, phash, id) FROM stdin;
Andy	Paris	submttd	5	6191bc1e-c450-930b-3496-fc34f39901a8	9
Andy	NY	submttd	6	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3
Andy	Paris	accepted	9	aa853ede-e166-e658-e4e2-8affb554131d	9
Andy	Paris	rejected	11	d68c3a88-ec75-b008-79c3-455246019a20	9
Andy	NY	accepted	16	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3
Andy	NY	rejected	18	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3
Andy	Paris	complete	25	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9
Andy	NY	complete	46	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3
Andy	Paris	reimbursed	70	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9
Andy	NY	reimbursed	116	7d78c511-18d0-2b22-b41d-0e4993029154	3
\.


--
-- Data for Name: CurrReq_endw_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_endw_state_log_dump" (session_id, rid, id) FROM stdin;
46	6	3
61	5	9
74	9	9
96	16	3
97	11	9
98	18	3
122	25	9
132	25	9
138	6	3
151	25	9
153	25	9
161	6	3
163	46	3
174	5	9
181	9	9
185	16	3
186	70	9
187	18	3
197	16	3
198	70	9
199	18	3
213	16	3
222	16	3
223	11	9
224	18	3
226	11	9
227	18	3
228	11	9
229	116	3
237	25	9
239	46	3
249	25	9
251	46	3
253	25	9
255	46	3
262	25	9
264	46	3
266	25	9
268	46	3
270	25	9
272	46	3
274	25	9
276	46	3
284	70	9
285	116	3
288	70	9
289	116	3
291	70	9
292	116	3
295	11	9
296	116	3
298	11	9
299	18	3
301	11	9
302	116	3
304	11	9
305	116	3
\.


--
-- Data for Name: CurrReq_fillrmb_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_fillrmb_dump" (empl, dest, status, rid, phash, id, session_id) FROM stdin;
Andy	Paris	complete	25	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	12
Andy	Paris	complete	27	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	13
Andy	NY	complete	46	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	24
Andy	Paris	complete	64	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	34
Andy	NY	complete	99	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	53
Andy	NY	complete	122	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	65
Andy	Paris	complete	126	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	68
Andy	Paris	complete	132	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	71
Andy	NY	complete	173	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	93
Andy	Paris	complete	209	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	113
Andy	NY	complete	216	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	117
Andy	Paris	complete	226	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	123
Andy	NY	complete	232	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	126
Andy	NY	complete	234	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	127
Andy	NY	complete	258	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	140
Andy	NY	complete	260	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	141
Andy	NY	complete	267	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	145
Andy	NY	complete	269	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	146
Andy	NY	complete	302	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	164
Andy	Paris	complete	329	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	178
Andy	NY	complete	336	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	182
Andy	NY	complete	357	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	193
Andy	NY	complete	359	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	194
Andy	NY	complete	387	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	209
Andy	NY	complete	389	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	210
Andy	NY	complete	404	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	218
Andy	NY	complete	406	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	219
Andy	Paris	complete	445	07d079b2-4a63-db14-aa5d-2ba41cd5e132	9	240
Andy	NY	complete	450	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	243
Andy	NY	complete	475	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	256
Andy	NY	complete	477	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	257
Andy	NY	complete	516	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	277
Andy	NY	complete	518	c92dda3e-ec5a-a726-7872-cc5db1ebd17c	3	278
\.


--
-- Data for Name: CurrReq_fillrmb_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_fillrmb_state_log_dump" (session_id, rid, id) FROM stdin;
34	6	3
53	5	9
65	9	9
68	16	3
71	18	3
93	11	9
113	46	3
117	25	9
126	25	9
127	25	9
140	25	9
141	25	9
145	25	9
146	25	9
178	116	3
182	70	9
193	70	9
194	70	9
209	11	9
210	11	9
218	11	9
219	11	9
\.


--
-- Data for Name: CurrReq_revwreimb_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_revwreimb_dump" (empl, dest, status, rid, phash, id, session_id) FROM stdin;
Andy	Paris	reimbursed	70	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	38
Andy	Paris	rejected	74	d68c3a88-ec75-b008-79c3-455246019a20	9	40
Andy	NY	reimbursed	116	7d78c511-18d0-2b22-b41d-0e4993029154	3	63
Andy	Paris	reimbursed	146	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	80
Andy	Paris	rejected	165	d68c3a88-ec75-b008-79c3-455246019a20	9	90
Andy	NY	reimbursed	196	7d78c511-18d0-2b22-b41d-0e4993029154	3	107
Andy	NY	reimbursed	212	7d78c511-18d0-2b22-b41d-0e4993029154	3	116
Andy	Paris	reimbursed	219	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	120
Andy	Paris	reimbursed	222	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	121
Andy	Paris	reimbursed	237	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	130
Andy	Paris	reimbursed	240	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	131
Andy	Paris	rejected	263	d68c3a88-ec75-b008-79c3-455246019a20	9	144
Andy	Paris	rejected	272	d68c3a88-ec75-b008-79c3-455246019a20	9	149
Andy	Paris	rejected	275	d68c3a88-ec75-b008-79c3-455246019a20	9	150
Andy	Paris	rejected	279	d68c3a88-ec75-b008-79c3-455246019a20	9	152
Andy	NY	reimbursed	298	7d78c511-18d0-2b22-b41d-0e4993029154	3	162
Andy	NY	reimbursed	324	7d78c511-18d0-2b22-b41d-0e4993029154	3	176
Andy	Paris	reimbursed	325	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	177
Andy	Paris	reimbursed	345	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	188
Andy	NY	reimbursed	348	7d78c511-18d0-2b22-b41d-0e4993029154	3	189
Andy	Paris	reimbursed	349	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	190
Andy	NY	reimbursed	352	7d78c511-18d0-2b22-b41d-0e4993029154	3	191
Andy	Paris	reimbursed	353	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	192
Andy	NY	reimbursed	378	7d78c511-18d0-2b22-b41d-0e4993029154	3	205
Andy	Paris	rejected	379	d68c3a88-ec75-b008-79c3-455246019a20	9	206
Andy	NY	rejected	382	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	207
Andy	Paris	rejected	383	d68c3a88-ec75-b008-79c3-455246019a20	9	208
Andy	NY	reimbursed	395	7d78c511-18d0-2b22-b41d-0e4993029154	3	214
Andy	Paris	rejected	396	d68c3a88-ec75-b008-79c3-455246019a20	9	215
Andy	NY	reimbursed	399	7d78c511-18d0-2b22-b41d-0e4993029154	3	216
Andy	Paris	rejected	400	d68c3a88-ec75-b008-79c3-455246019a20	9	217
Andy	Paris	rejected	415	d68c3a88-ec75-b008-79c3-455246019a20	9	225
Andy	NY	reimbursed	425	7d78c511-18d0-2b22-b41d-0e4993029154	3	230
Andy	Paris	reimbursed	437	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	236
Andy	NY	reimbursed	441	7d78c511-18d0-2b22-b41d-0e4993029154	3	238
Andy	Paris	reimbursed	459	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	248
Andy	NY	reimbursed	463	7d78c511-18d0-2b22-b41d-0e4993029154	3	250
Andy	Paris	reimbursed	467	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	252
Andy	NY	reimbursed	471	7d78c511-18d0-2b22-b41d-0e4993029154	3	254
Andy	Paris	rejected	484	d68c3a88-ec75-b008-79c3-455246019a20	9	261
Andy	NY	reimbursed	488	7d78c511-18d0-2b22-b41d-0e4993029154	3	263
Andy	Paris	rejected	492	d68c3a88-ec75-b008-79c3-455246019a20	9	265
Andy	NY	rejected	496	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	267
Andy	Paris	rejected	500	d68c3a88-ec75-b008-79c3-455246019a20	9	269
Andy	NY	reimbursed	504	7d78c511-18d0-2b22-b41d-0e4993029154	3	271
Andy	Paris	rejected	508	d68c3a88-ec75-b008-79c3-455246019a20	9	273
Andy	NY	reimbursed	512	7d78c511-18d0-2b22-b41d-0e4993029154	3	275
Andy	Paris	reimbursed	532	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	286
Andy	NY	reimbursed	534	7d78c511-18d0-2b22-b41d-0e4993029154	3	287
Andy	NY	reimbursed	540	7d78c511-18d0-2b22-b41d-0e4993029154	3	290
Andy	Paris	reimbursed	546	ac894e2d-c95c-264f-2b4a-e465314e0cc5	9	293
Andy	NY	reimbursed	548	7d78c511-18d0-2b22-b41d-0e4993029154	3	294
Andy	Paris	rejected	554	d68c3a88-ec75-b008-79c3-455246019a20	9	297
Andy	NY	rejected	560	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	300
Andy	NY	reimbursed	566	7d78c511-18d0-2b22-b41d-0e4993029154	3	303
Andy	Paris	rejected	572	d68c3a88-ec75-b008-79c3-455246019a20	9	306
Andy	NY	reimbursed	574	7d78c511-18d0-2b22-b41d-0e4993029154	3	307
\.


--
-- Data for Name: CurrReq_revwreimb_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_revwreimb_state_log_dump" (session_id, rid, id) FROM stdin;
80	6	3
90	6	3
107	5	9
116	9	9
120	16	3
121	18	3
130	16	3
131	18	3
144	16	3
149	16	3
150	18	3
152	18	3
162	11	9
176	25	9
177	46	3
189	25	9
190	46	3
191	25	9
192	46	3
205	25	9
206	46	3
207	25	9
208	46	3
214	25	9
215	46	3
216	25	9
217	46	3
236	116	3
238	70	9
248	116	3
250	70	9
252	116	3
254	70	9
261	116	3
263	11	9
265	18	3
267	11	9
269	116	3
271	11	9
273	116	3
275	11	9
\.


--
-- Data for Name: CurrReq_rvwreq_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_rvwreq_dump" (empl, dest, status, rid, phash, id, session_id) FROM stdin;
Andy	Paris	accepted	9	aa853ede-e166-e658-e4e2-8affb554131d	9	3
Andy	Paris	rejected	11	d68c3a88-ec75-b008-79c3-455246019a20	9	4
Andy	NY	accepted	16	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	7
Andy	NY	rejected	18	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	8
Andy	NY	accepted	34	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	17
Andy	NY	rejected	36	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	18
Andy	Paris	accepted	38	aa853ede-e166-e658-e4e2-8affb554131d	9	20
Andy	Paris	rejected	40	d68c3a88-ec75-b008-79c3-455246019a20	9	21
Andy	NY	accepted	55	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	29
Andy	NY	rejected	59	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	31
Andy	NY	accepted	77	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	41
Andy	NY	rejected	81	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	43
Andy	Paris	accepted	90	aa853ede-e166-e658-e4e2-8affb554131d	9	48
Andy	Paris	rejected	94	d68c3a88-ec75-b008-79c3-455246019a20	9	50
Andy	Paris	accepted	104	aa853ede-e166-e658-e4e2-8affb554131d	9	56
Andy	Paris	rejected	108	d68c3a88-ec75-b008-79c3-455246019a20	9	58
Andy	NY	accepted	138	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	75
Andy	NY	accepted	140	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	76
Andy	NY	rejected	142	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	77
Andy	NY	rejected	144	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	78
Andy	NY	accepted	153	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	83
Andy	NY	accepted	155	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	84
Andy	NY	rejected	159	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	86
Andy	NY	rejected	161	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	87
Andy	NY	accepted	182	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	99
Andy	NY	rejected	184	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	100
Andy	Paris	accepted	188	aa853ede-e166-e658-e4e2-8affb554131d	9	102
Andy	Paris	rejected	192	d68c3a88-ec75-b008-79c3-455246019a20	9	104
Andy	Paris	accepted	198	aa853ede-e166-e658-e4e2-8affb554131d	9	108
Andy	Paris	rejected	200	d68c3a88-ec75-b008-79c3-455246019a20	9	109
Andy	NY	accepted	244	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	133
Andy	NY	rejected	248	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	135
Andy	NY	accepted	283	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	154
Andy	NY	accepted	285	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	155
Andy	NY	rejected	289	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	157
Andy	NY	rejected	291	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	158
Andy	Paris	accepted	311	aa853ede-e166-e658-e4e2-8affb554131d	9	169
Andy	Paris	rejected	315	d68c3a88-ec75-b008-79c3-455246019a20	9	171
Andy	NY	accepted	368	93aa9b5c-dd7a-b71c-3732-79ece4b93c94	3	200
Andy	NY	rejected	372	d43b13d7-3b4c-6617-8074-d36a8ce6801d	3	202
Andy	Paris	accepted	427	aa853ede-e166-e658-e4e2-8affb554131d	9	231
Andy	Paris	rejected	431	d68c3a88-ec75-b008-79c3-455246019a20	9	233
\.


--
-- Data for Name: CurrReq_rvwreq_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_rvwreq_state_log_dump" (session_id, rid, id) FROM stdin;
17	5	9
18	5	9
20	6	3
21	6	3
29	9	9
31	9	9
41	11	9
43	11	9
48	16	3
50	16	3
56	18	3
58	18	3
75	25	9
76	25	9
77	25	9
78	25	9
83	25	9
84	25	9
86	25	9
87	25	9
102	46	3
104	46	3
133	70	9
135	70	9
154	11	9
155	11	9
157	11	9
158	11	9
169	116	3
171	116	3
\.


--
-- Data for Name: CurrReq_startw_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_startw_dump" (empl, dest, status, rid, phash, id, session_id) FROM stdin;
Andy	Paris	submttd	5	6191bc1e-c450-930b-3496-fc34f39901a8	9	1
Andy	NY	submttd	6	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	2
Andy	NY	submttd	13	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	6
Andy	Paris	submttd	20	6191bc1e-c450-930b-3496-fc34f39901a8	9	10
Andy	NY	submttd	23	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	11
Andy	NY	submttd	30	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	15
Andy	Paris	submttd	44	6191bc1e-c450-930b-3496-fc34f39901a8	9	23
Andy	Paris	submttd	51	6191bc1e-c450-930b-3496-fc34f39901a8	9	27
Andy	NY	submttd	69	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	37
Andy	NY	submttd	73	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	39
Andy	NY	submttd	87	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	47
Andy	Paris	submttd	115	6191bc1e-c450-930b-3496-fc34f39901a8	9	62
Andy	Paris	submttd	118	6191bc1e-c450-930b-3496-fc34f39901a8	9	64
Andy	NY	submttd	149	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	81
Andy	NY	submttd	168	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	91
Andy	Paris	submttd	204	6191bc1e-c450-930b-3496-fc34f39901a8	9	111
Andy	NY	submttd	254	f095d4d4-0da8-1d22-cfa4-61ec231b1866	3	139
Andy	Paris	submttd	321	6191bc1e-c450-930b-3496-fc34f39901a8	9	175
\.


--
-- Data for Name: CurrReq_startw_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_startw_state_log_dump" (session_id, rid, id) FROM stdin;
6	5	9
10	6	3
11	9	9
15	11	9
23	16	3
27	18	3
37	25	9
39	25	9
62	46	3
81	70	9
91	11	9
111	116	3
\.


--
-- Data for Name: CurrReq_state_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "CurrReq_state_log" (state, rid, id) FROM stdin;
2	5	9
3	6	3
4	9	9
5	11	9
6	6	3
6	5	9
7	16	3
8	18	3
9	6	3
9	9	9
10	25	9
11	25	9
12	6	3
12	11	9
14	16	3
14	5	9
15	18	3
15	5	9
16	46	3
18	16	3
18	9	9
19	18	3
19	9	9
20	25	9
20	6	3
21	70	9
22	6	3
22	25	9
23	11	9
24	16	3
24	11	9
25	18	3
25	11	9
26	6	3
27	46	3
27	5	9
28	5	9
29	116	3
30	46	3
30	9	9
31	25	9
31	16	3
32	25	9
32	18	3
33	9	9
34	16	3
34	25	9
35	18	3
35	25	9
36	70	9
36	6	3
38	16	3
38	25	9
39	16	3
39	25	9
40	18	3
40	25	9
41	18	3
41	25	9
42	11	9
42	6	3
43	46	3
43	11	9
44	16	3
45	11	9
46	18	3
47	116	3
47	5	9
49	25	9
49	46	3
50	116	3
50	9	9
51	70	9
51	16	3
52	70	9
52	18	3
53	25	9
54	46	3
54	25	9
55	46	3
55	25	9
56	70	9
56	16	3
57	70	9
57	18	3
58	6	3
59	46	3
59	25	9
60	46	3
60	25	9
61	11	9
61	16	3
62	46	3
62	25	9
63	46	3
63	25	9
64	11	9
64	16	3
65	11	9
65	18	3
66	25	9
67	11	9
67	18	3
68	116	3
68	11	9
69	46	3
71	5	9
72	116	3
72	25	9
73	70	9
73	46	3
74	9	9
75	16	3
76	70	9
77	18	3
78	116	3
78	25	9
79	70	9
79	46	3
80	116	3
80	25	9
81	70	9
81	46	3
82	16	3
83	18	3
84	116	3
84	25	9
85	11	9
85	46	3
86	18	3
86	25	9
87	11	9
87	46	3
88	116	3
88	25	9
89	11	9
89	46	3
90	116	3
90	25	9
91	11	9
91	46	3
92	16	3
93	11	9
94	18	3
95	11	9
96	116	3
97	70	9
97	116	3
98	25	9
99	46	3
101	70	9
101	116	3
102	46	3
103	70	9
103	116	3
104	25	9
105	46	3
106	11	9
106	116	3
107	25	9
108	11	9
108	18	3
109	46	3
110	11	9
110	116	3
111	46	3
112	11	9
112	116	3
113	25	9
114	46	3
116	70	9
117	116	3
118	116	3
119	70	9
120	116	3
121	11	9
122	18	3
123	116	3
124	11	9
125	116	3
\.


--
-- Data for Name: Dest; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Dest" (id, dest) FROM stdin;
13	NY
14	Genova
12	Paris
\.


--
-- Data for Name: Empl; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Empl" (id, empl) FROM stdin;
15	Bob
16	Kriss
17	Andy
\.


--
-- Data for Name: Pending; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Pending" (empl, dest, rid, phash, id) FROM stdin;
Andy	Paris	1	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9
Andy	NY	2	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3
\.


--
-- Data for Name: Pending_startw_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Pending_startw_state_log_dump" (session_id, rid, id) FROM stdin;
1	2	3
2	1	9
\.


--
-- Data for Name: Pending_state_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Pending_state_log" (state, rid, id) FROM stdin;
1	1	9
1	2	3
2	2	3
3	1	9
4	2	3
5	2	3
7	1	9
8	1	9
10	2	3
11	2	3
13	2	3
16	1	9
17	1	9
21	2	3
23	2	3
29	1	9
37	2	3
48	1	9
\.


--
-- Data for Name: Rejected; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Rejected" (empl, dest, rid, phash, id) FROM stdin;
Andy	Paris	31	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9
Andy	NY	52	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3
\.


--
-- Data for Name: Rejected_endw_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Rejected_endw_dump" (empl, dest, rid, phash, id, session_id) FROM stdin;
Andy	Paris	31	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	16
Andy	NY	52	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	28
Andy	Paris	85	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	46
Andy	NY	112	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	61
Andy	NY	135	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	74
Andy	Paris	169	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	92
Andy	Paris	176	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	96
Andy	NY	179	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	97
Andy	Paris	180	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	98
Andy	NY	223	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	122
Andy	NY	241	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	132
Andy	NY	276	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	151
Andy	NY	280	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	153
Andy	Paris	295	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	161
Andy	Paris	299	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	163
Andy	Paris	306	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	167
Andy	NY	308	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	168
Andy	NY	342	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	186
Andy	NY	365	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	198
Andy	Paris	392	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	213
Andy	Paris	409	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	222
Andy	NY	412	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	223
Andy	Paris	413	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	224
Andy	NY	418	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	226
Andy	Paris	419	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	227
Andy	Paris	423	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	229
Andy	NY	456	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	247
Andy	NY	481	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	260
Andy	Paris	489	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	264
Andy	NY	493	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	266
Andy	Paris	497	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	268
Andy	Paris	505	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	272
Andy	Paris	513	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	276
Andy	Paris	520	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	280
Andy	NY	522	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	281
Andy	Paris	524	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	282
Andy	Paris	552	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	296
Andy	NY	557	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	298
Andy	Paris	558	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	299
Andy	Paris	564	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	302
Andy	Paris	570	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	305
Andy	Paris	586	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	313
Andy	NY	588	d43ef885-8f67-ed91-59d4-c379c8a1aa9f	3	314
Andy	Paris	592	19f8ed76-cca9-943b-2c05-8fa11bf8483c	9	316
\.


--
-- Data for Name: Rejected_endw_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Rejected_endw_state_log_dump" (session_id, rid, id) FROM stdin;
167	52	3
168	31	9
246	52	3
280	52	3
281	31	9
283	31	9
314	31	9
315	31	9
317	31	9
\.


--
-- Data for Name: Rejected_state_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "Rejected_state_log" (state, rid, id) FROM stdin;
13	31	9
17	52	3
26	31	9
28	52	3
33	52	3
44	31	9
45	52	3
46	31	9
53	52	3
66	52	3
69	31	9
70	31	9
70	52	3
76	52	3
92	31	9
93	52	3
94	31	9
96	31	9
100	52	3
109	31	9
111	31	9
114	31	9
115	31	9
122	31	9
123	31	9
125	31	9
128	31	9
\.


--
-- Data for Name: TS; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TS" (curr, next, action, binding) FROM stdin;
1	2	startw	3
1	3	startw	4
2	4	rvwreq	7
2	5	rvwreq	7
2	6	startw	8
3	7	rvwreq	14
3	8	rvwreq	14
3	6	startw	15
4	9	startw	21
4	10	fillrmb	22
4	11	fillrmb	22
5	12	startw	28
5	13	endw	29
6	14	rvwreq	32
6	15	rvwreq	32
6	9	rvwreq	33
6	12	rvwreq	33
7	14	startw	42
7	16	fillrmb	43
8	15	startw	49
8	17	endw	50
9	18	rvwreq	53
9	19	rvwreq	53
9	20	fillrmb	54
10	20	startw	67
10	21	revwreimb	68
11	22	startw	71
11	23	revwreimb	72
12	24	rvwreq	75
12	25	rvwreq	75
12	26	endw	76
13	26	startw	86
14	18	rvwreq	88
14	24	rvwreq	88
14	27	fillrmb	89
15	19	rvwreq	102
15	25	rvwreq	102
15	28	endw	103
16	27	startw	113
16	29	revwreimb	114
17	28	startw	117
18	30	fillrmb	119
18	31	fillrmb	120
19	32	fillrmb	129
19	33	endw	130
20	31	rvwreq	136
20	34	rvwreq	136
20	32	rvwreq	136
20	35	rvwreq	136
20	36	revwreimb	137
21	36	startw	147
21	37	endw	148
22	38	rvwreq	151
22	39	rvwreq	151
22	40	rvwreq	151
22	41	rvwreq	151
22	42	revwreimb	152
23	42	startw	166
23	13	endw	167
24	43	fillrmb	170
24	44	endw	171
25	45	endw	177
25	46	endw	178
26	44	rvwreq	181
26	46	rvwreq	181
27	30	rvwreq	186
27	43	rvwreq	186
27	47	revwreimb	187
28	33	rvwreq	197
28	45	rvwreq	197
29	47	startw	202
29	48	endw	203
30	49	fillrmb	206
30	50	revwreimb	207
31	49	fillrmb	213
31	51	revwreimb	214
32	52	revwreimb	220
32	53	endw	221
33	53	fillrmb	224
34	54	fillrmb	229
34	55	fillrmb	229
34	56	revwreimb	230
35	57	revwreimb	238
35	53	endw	239
36	51	rvwreq	242
36	52	rvwreq	242
36	58	endw	243
37	58	startw	253
38	59	fillrmb	255
38	60	fillrmb	255
38	61	revwreimb	256
39	62	fillrmb	264
39	63	fillrmb	264
39	64	revwreimb	265
40	65	revwreimb	273
40	66	endw	274
41	67	revwreimb	277
41	66	endw	278
42	61	rvwreq	281
42	64	rvwreq	281
42	65	rvwreq	281
42	67	rvwreq	281
42	26	endw	282
43	68	revwreimb	296
43	69	endw	297
44	69	fillrmb	300
45	70	endw	305
46	70	endw	307
47	50	rvwreq	309
47	68	rvwreq	309
47	71	endw	310
48	71	startw	320
49	72	revwreimb	322
49	73	revwreimb	323
50	72	fillrmb	326
50	74	endw	327
51	73	fillrmb	333
51	75	endw	334
52	76	endw	340
52	77	endw	341
53	76	revwreimb	344
54	78	revwreimb	346
54	79	revwreimb	347
55	80	revwreimb	350
55	81	revwreimb	351
56	79	fillrmb	354
56	81	fillrmb	354
56	82	endw	355
57	76	endw	363
57	83	endw	364
58	75	rvwreq	367
58	77	rvwreq	367
59	84	revwreimb	376
59	85	revwreimb	377
60	86	revwreimb	380
60	87	revwreimb	381
61	85	fillrmb	384
61	87	fillrmb	384
61	44	endw	385
62	88	revwreimb	393
62	89	revwreimb	394
63	90	revwreimb	397
63	91	revwreimb	398
64	89	fillrmb	401
64	91	fillrmb	401
64	92	endw	402
65	93	endw	410
65	46	endw	411
66	93	revwreimb	414
67	93	endw	416
67	94	endw	417
68	95	endw	420
68	96	endw	421
69	96	revwreimb	424
71	74	rvwreq	426
71	95	rvwreq	426
72	97	revwreimb	435
72	98	endw	436
73	97	revwreimb	439
73	99	endw	440
74	98	fillrmb	443
75	99	fillrmb	448
76	100	endw	453
77	100	endw	455
78	101	revwreimb	457
78	98	endw	458
79	101	revwreimb	461
79	102	endw	462
80	103	revwreimb	465
80	104	endw	466
81	103	revwreimb	469
81	105	endw	470
82	102	fillrmb	473
82	105	fillrmb	473
83	100	endw	480
84	106	revwreimb	482
84	107	endw	483
85	106	revwreimb	486
85	69	endw	487
86	108	revwreimb	490
86	66	endw	491
87	108	revwreimb	494
87	109	endw	495
88	110	revwreimb	498
88	107	endw	499
89	110	revwreimb	502
89	111	endw	503
90	112	revwreimb	506
90	113	endw	507
91	112	revwreimb	510
91	114	endw	511
92	114	fillrmb	514
92	111	fillrmb	514
93	70	endw	519
94	70	endw	521
95	115	endw	523
96	115	endw	525
97	116	endw	527
97	117	endw	528
98	116	revwreimb	531
99	117	revwreimb	533
101	116	endw	535
101	118	endw	536
102	118	revwreimb	539
103	119	endw	541
103	120	endw	542
104	119	revwreimb	545
105	120	revwreimb	547
106	121	endw	549
106	96	endw	550
107	121	revwreimb	553
108	93	endw	555
108	122	endw	556
109	122	revwreimb	559
110	121	endw	561
110	123	endw	562
111	123	revwreimb	565
112	124	endw	567
112	125	endw	568
113	124	revwreimb	571
114	125	revwreimb	573
116	126	endw	575
117	126	endw	577
118	126	endw	579
119	127	endw	581
120	127	endw	583
121	115	endw	585
122	70	endw	587
123	115	endw	589
124	128	endw	591
125	128	endw	593
\.


--
-- Data for Name: TS_enabled; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TS_enabled" (enabled, id) FROM stdin;
t	1
\.


--
-- Data for Name: TrvlCost; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlCost" (cost, rid, phash, fid) FROM stdin;
0	24	47e9d1d3-29e2-c974-08fb-c079557d00e6	9
1	26	442857fe-1712-6c1f-4218-93a9dc3f805e	9
0	45	3a65da28-1bf2-56a8-a600-d46e0c99625f	3
1	233	c9d8859b-4eeb-120d-209c-937fca3a53af	3
\.


--
-- Data for Name: TrvlCost_endw_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlCost_endw_state_log_dump" (session_id, rid, fid) FROM stdin;
122	24	9
132	24	9
151	26	9
153	26	9
163	45	3
186	24	9
198	24	9
223	26	9
226	26	9
229	45	3
237	24	9
239	45	3
249	24	9
251	45	3
253	24	9
255	233	3
262	26	9
264	45	3
266	26	9
268	233	3
270	26	9
272	45	3
274	26	9
276	233	3
284	24	9
285	45	3
288	24	9
289	45	3
291	24	9
292	233	3
295	26	9
296	45	3
298	26	9
299	233	3
301	26	9
302	45	3
304	26	9
305	233	3
\.


--
-- Data for Name: TrvlCost_fillrmb_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlCost_fillrmb_dump" (cost, rid, phash, fid, session_id) FROM stdin;
0	24	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	12
1	26	442857fe-1712-6c1f-4218-93a9dc3f805e	9	13
0	45	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	24
0	63	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	34
0	98	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	53
0	121	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	65
0	125	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	68
0	131	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	71
0	172	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	93
0	208	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	113
0	215	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	117
0	225	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	123
0	231	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	126
1	233	c9d8859b-4eeb-120d-209c-937fca3a53af	3	127
0	257	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	140
1	259	c9d8859b-4eeb-120d-209c-937fca3a53af	3	141
0	266	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	145
1	268	c9d8859b-4eeb-120d-209c-937fca3a53af	3	146
0	301	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	164
0	328	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	178
0	335	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	182
0	356	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	193
1	358	c9d8859b-4eeb-120d-209c-937fca3a53af	3	194
0	386	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	209
1	388	c9d8859b-4eeb-120d-209c-937fca3a53af	3	210
0	403	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	218
1	405	c9d8859b-4eeb-120d-209c-937fca3a53af	3	219
0	444	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	240
0	449	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	243
0	474	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	256
1	476	c9d8859b-4eeb-120d-209c-937fca3a53af	3	257
1	515	c9d8859b-4eeb-120d-209c-937fca3a53af	3	277
0	517	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	278
\.


--
-- Data for Name: TrvlCost_fillrmb_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlCost_fillrmb_state_log_dump" (session_id, rid, fid) FROM stdin;
113	45	3
117	24	9
126	24	9
127	24	9
140	26	9
141	26	9
145	26	9
146	26	9
178	45	3
182	24	9
193	24	9
194	24	9
209	26	9
210	26	9
218	26	9
219	26	9
\.


--
-- Data for Name: TrvlCost_state_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlCost_state_log" (state, rid, fid) FROM stdin;
10	24	9
11	26	9
16	45	3
20	24	9
21	24	9
22	26	9
23	26	9
27	45	3
29	45	3
30	45	3
31	24	9
32	24	9
34	24	9
35	24	9
36	24	9
38	26	9
39	26	9
40	26	9
41	26	9
42	26	9
43	45	3
47	45	3
49	24	9
49	45	3
50	45	3
51	24	9
52	24	9
53	24	9
54	45	3
54	24	9
55	233	3
55	24	9
56	24	9
57	24	9
59	45	3
59	26	9
60	233	3
60	26	9
61	26	9
62	45	3
62	26	9
63	233	3
63	26	9
64	26	9
65	26	9
66	26	9
67	26	9
68	45	3
69	45	3
72	24	9
72	45	3
73	24	9
73	45	3
76	24	9
78	45	3
78	24	9
79	45	3
79	24	9
80	233	3
80	24	9
81	233	3
81	24	9
84	45	3
84	26	9
85	45	3
85	26	9
86	233	3
86	26	9
87	233	3
87	26	9
88	45	3
88	26	9
89	45	3
89	26	9
90	233	3
90	26	9
91	233	3
91	26	9
93	26	9
96	45	3
97	24	9
97	45	3
98	24	9
99	45	3
101	45	3
101	24	9
102	45	3
103	233	3
103	24	9
104	24	9
105	233	3
106	45	3
106	26	9
107	26	9
108	233	3
108	26	9
109	233	3
110	45	3
110	26	9
111	45	3
112	233	3
112	26	9
113	26	9
114	233	3
116	24	9
117	45	3
118	45	3
119	24	9
120	233	3
121	26	9
122	233	3
123	45	3
124	26	9
125	233	3
\.


--
-- Data for Name: TrvlMaxAmnt; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlMaxAmnt" ("maxAmnt", rid, phash, fid) FROM stdin;
0	10	47e9d1d3-29e2-c974-08fb-c079557d00e6	9
0	17	3a65da28-1bf2-56a8-a600-d46e0c99625f	3
1	141	c9d8859b-4eeb-120d-209c-937fca3a53af	3
\.


--
-- Data for Name: TrvlMaxAmnt_endw_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlMaxAmnt_endw_state_log_dump" (session_id, rid, fid) FROM stdin;
74	10	9
96	17	3
97	10	9
98	17	3
122	10	9
132	10	9
151	10	9
153	10	9
163	17	3
181	10	9
185	17	3
186	10	9
187	17	3
197	141	3
198	10	9
199	141	3
213	17	3
222	141	3
223	10	9
224	17	3
226	10	9
227	141	3
228	10	9
229	17	3
237	10	9
239	17	3
249	10	9
251	141	3
253	10	9
255	141	3
262	10	9
264	17	3
266	10	9
268	17	3
270	10	9
272	141	3
274	10	9
276	141	3
284	10	9
285	17	3
288	10	9
289	141	3
291	10	9
292	141	3
295	10	9
296	17	3
298	10	9
299	17	3
301	10	9
302	141	3
304	10	9
305	141	3
\.


--
-- Data for Name: TrvlMaxAmnt_rvwreq_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlMaxAmnt_rvwreq_dump" ("maxAmnt", rid, phash, fid, session_id) FROM stdin;
0	10	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	3
0	12	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	4
0	17	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	7
0	19	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	8
0	35	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	17
0	37	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	18
0	39	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	20
0	41	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	21
0	56	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	29
0	60	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	31
0	78	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	41
0	82	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	43
0	91	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	48
0	95	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	50
0	105	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	56
0	109	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	58
0	139	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	75
1	141	c9d8859b-4eeb-120d-209c-937fca3a53af	3	76
0	143	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	77
1	145	c9d8859b-4eeb-120d-209c-937fca3a53af	3	78
0	154	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	83
1	156	c9d8859b-4eeb-120d-209c-937fca3a53af	3	84
0	160	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	86
1	162	c9d8859b-4eeb-120d-209c-937fca3a53af	3	87
0	183	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	99
0	185	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	100
0	189	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	102
0	193	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	104
0	199	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	108
0	201	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	109
0	245	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	133
0	249	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	135
0	284	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	154
1	286	c9d8859b-4eeb-120d-209c-937fca3a53af	3	155
0	290	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	157
1	292	c9d8859b-4eeb-120d-209c-937fca3a53af	3	158
0	312	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	169
0	316	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	171
0	369	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	200
0	373	3a65da28-1bf2-56a8-a600-d46e0c99625f	3	202
0	428	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	231
0	432	47e9d1d3-29e2-c974-08fb-c079557d00e6	9	233
\.


--
-- Data for Name: TrvlMaxAmnt_rvwreq_state_log_dump; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlMaxAmnt_rvwreq_state_log_dump" (session_id, rid, fid) FROM stdin;
29	10	9
31	10	9
41	10	9
43	10	9
48	17	3
50	17	3
56	17	3
58	17	3
75	10	9
76	10	9
77	10	9
78	10	9
83	10	9
84	10	9
86	10	9
87	10	9
102	17	3
104	17	3
133	10	9
135	10	9
154	10	9
155	10	9
157	10	9
158	10	9
169	17	3
171	17	3
\.


--
-- Data for Name: TrvlMaxAmnt_state_log; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY "TrvlMaxAmnt_state_log" (state, rid, fid) FROM stdin;
4	10	9
5	10	9
7	17	3
8	17	3
9	10	9
10	10	9
11	10	9
12	10	9
14	17	3
15	17	3
16	17	3
18	17	3
18	10	9
19	17	3
19	10	9
20	10	9
21	10	9
22	10	9
23	10	9
24	17	3
24	10	9
25	17	3
25	10	9
27	17	3
29	17	3
30	17	3
30	10	9
31	17	3
31	10	9
32	17	3
32	10	9
33	10	9
34	141	3
34	10	9
35	141	3
35	10	9
36	10	9
38	17	3
38	10	9
39	141	3
39	10	9
40	17	3
40	10	9
41	141	3
41	10	9
42	10	9
43	17	3
43	10	9
44	17	3
45	10	9
46	17	3
47	17	3
49	17	3
49	10	9
50	17	3
50	10	9
51	17	3
51	10	9
52	17	3
52	10	9
53	10	9
54	141	3
54	10	9
55	141	3
55	10	9
56	141	3
56	10	9
57	141	3
57	10	9
59	17	3
59	10	9
60	17	3
60	10	9
61	17	3
61	10	9
62	141	3
62	10	9
63	141	3
63	10	9
64	141	3
64	10	9
65	17	3
65	10	9
66	10	9
67	141	3
67	10	9
68	17	3
68	10	9
69	17	3
72	17	3
72	10	9
73	17	3
73	10	9
74	10	9
75	17	3
76	10	9
77	17	3
78	141	3
78	10	9
79	141	3
79	10	9
80	141	3
80	10	9
81	141	3
81	10	9
82	141	3
83	141	3
84	17	3
84	10	9
85	17	3
85	10	9
86	17	3
86	10	9
87	17	3
87	10	9
88	141	3
88	10	9
89	141	3
89	10	9
90	141	3
90	10	9
91	141	3
91	10	9
92	141	3
93	10	9
94	141	3
95	10	9
96	17	3
97	17	3
97	10	9
98	10	9
99	17	3
101	141	3
101	10	9
102	141	3
103	141	3
103	10	9
104	10	9
105	141	3
106	17	3
106	10	9
107	10	9
108	17	3
108	10	9
109	17	3
110	141	3
110	10	9
111	141	3
112	141	3
112	10	9
113	10	9
114	141	3
116	10	9
117	17	3
118	141	3
119	10	9
120	141	3
121	10	9
122	17	3
123	141	3
124	10	9
125	141	3
\.


--
-- Data for Name: action_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY action_metadata (id, action, service) FROM stdin;
1	endw	\N
3	revwreimb	\N
6	startw	\N
2	fillrmb	1
5	rvwreq	2
4	rvwreq	3
\.


--
-- Data for Name: current_session_id; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY current_session_id (id, session) FROM stdin;
1	317
\.


--
-- Data for Name: current_state; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY current_state (id, state) FROM stdin;
1	128
\.


--
-- Data for Name: endw_eff_1_eval_res; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY endw_eff_1_eval_res (cost, session_id) FROM stdin;
0	82
0	112
0	138
0	174
0	181
0	185
0	187
0	197
0	199
0	228
0	237
0	239
0	246
0	249
0	251
1	253
0	255
0	262
0	270
1	274
0	283
0	284
0	285
0	288
0	289
1	291
0	292
0	295
0	301
1	304
0	308
0	309
0	310
0	311
1	312
0	315
1	317
\.


--
-- Data for Name: endw_eff_2_eval_res; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY endw_eff_2_eval_res ("exists", session_id) FROM stdin;
t	16
t	28
t	46
t	61
t	74
f	82
t	92
t	96
t	97
t	98
f	112
t	122
t	132
f	138
t	151
t	153
t	161
t	163
t	167
t	168
f	174
f	181
f	185
t	186
f	187
f	197
t	198
f	199
t	213
t	222
t	223
t	224
t	226
t	227
f	228
t	229
f	237
f	239
f	246
t	247
f	249
f	251
f	253
f	255
t	260
f	262
t	264
t	266
t	268
f	270
t	272
f	274
t	276
t	280
t	281
t	282
f	283
f	284
f	285
f	288
f	289
f	291
f	292
f	295
t	296
t	298
t	299
f	301
t	302
f	304
t	305
f	308
f	309
f	310
f	311
f	312
t	313
t	314
f	315
t	316
f	317
\.


--
-- Data for Name: endw_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY endw_params (param_id, state, empl, dest, status, id_currreq, checked) FROM stdin;
29	5	Andy	Paris	rejected	9	t
50	8	Andy	NY	rejected	3	t
76	12	Andy	Paris	rejected	9	t
103	15	Andy	NY	rejected	3	t
130	19	Andy	NY	rejected	3	t
148	21	Andy	Paris	reimbursed	9	t
167	23	Andy	Paris	rejected	9	t
171	24	Andy	Paris	rejected	9	t
177	25	Andy	NY	rejected	3	t
178	25	Andy	Paris	rejected	9	t
203	29	Andy	NY	reimbursed	3	t
221	32	Andy	NY	rejected	3	t
239	35	Andy	NY	rejected	3	t
243	36	Andy	Paris	reimbursed	9	t
274	40	Andy	NY	rejected	3	t
278	41	Andy	NY	rejected	3	t
282	42	Andy	Paris	rejected	9	t
297	43	Andy	Paris	rejected	9	t
305	45	Andy	Paris	rejected	9	t
307	46	Andy	NY	rejected	3	t
310	47	Andy	NY	reimbursed	3	t
327	50	Andy	NY	reimbursed	3	t
334	51	Andy	Paris	reimbursed	9	t
340	52	Andy	NY	rejected	3	t
341	52	Andy	Paris	reimbursed	9	t
355	56	Andy	Paris	reimbursed	9	t
363	57	Andy	NY	rejected	3	t
364	57	Andy	Paris	reimbursed	9	t
385	61	Andy	Paris	rejected	9	t
402	64	Andy	Paris	rejected	9	t
410	65	Andy	NY	rejected	3	t
411	65	Andy	Paris	rejected	9	t
416	67	Andy	NY	rejected	3	t
417	67	Andy	Paris	rejected	9	t
420	68	Andy	NY	reimbursed	3	t
421	68	Andy	Paris	rejected	9	t
436	72	Andy	NY	reimbursed	3	t
440	73	Andy	Paris	reimbursed	9	t
453	76	Andy	Paris	reimbursed	9	t
455	77	Andy	NY	rejected	3	t
458	78	Andy	NY	reimbursed	3	t
462	79	Andy	Paris	reimbursed	9	t
466	80	Andy	NY	reimbursed	3	t
470	81	Andy	Paris	reimbursed	9	t
480	83	Andy	NY	rejected	3	t
483	84	Andy	NY	reimbursed	3	t
487	85	Andy	Paris	rejected	9	t
491	86	Andy	NY	rejected	3	t
495	87	Andy	Paris	rejected	9	t
499	88	Andy	NY	reimbursed	3	t
503	89	Andy	Paris	rejected	9	t
507	90	Andy	NY	reimbursed	3	t
511	91	Andy	Paris	rejected	9	t
519	93	Andy	Paris	rejected	9	t
521	94	Andy	NY	rejected	3	t
523	95	Andy	Paris	rejected	9	t
525	96	Andy	NY	reimbursed	3	t
527	97	Andy	NY	reimbursed	3	t
528	97	Andy	Paris	reimbursed	9	t
535	101	Andy	NY	reimbursed	3	t
536	101	Andy	Paris	reimbursed	9	t
541	103	Andy	NY	reimbursed	3	t
542	103	Andy	Paris	reimbursed	9	t
549	106	Andy	NY	reimbursed	3	t
550	106	Andy	Paris	rejected	9	t
555	108	Andy	NY	rejected	3	t
556	108	Andy	Paris	rejected	9	t
561	110	Andy	NY	reimbursed	3	t
562	110	Andy	Paris	rejected	9	t
567	112	Andy	NY	reimbursed	3	t
568	112	Andy	Paris	rejected	9	t
575	116	Andy	Paris	reimbursed	9	t
577	117	Andy	NY	reimbursed	3	t
579	118	Andy	NY	reimbursed	3	t
581	119	Andy	Paris	reimbursed	9	t
583	120	Andy	NY	reimbursed	3	t
585	121	Andy	Paris	rejected	9	t
587	122	Andy	NY	rejected	3	t
589	123	Andy	NY	reimbursed	3	t
591	124	Andy	Paris	rejected	9	t
593	125	Andy	NY	reimbursed	3	t
\.


--
-- Data for Name: fillrmb_cost_service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY fillrmb_cost_service (session_id, service_name, value) FROM stdin;
12	cost(Andy,Paris)	0
13	cost(Andy,Paris)	1
24	cost(Andy,NY)	0
25	cost(Andy,NY)	0
34	cost(Andy,Paris)	0
35	cost(Andy,Paris)	0
53	cost(Andy,NY)	0
54	cost(Andy,NY)	0
65	cost(Andy,NY)	0
66	cost(Andy,NY)	0
68	cost(Andy,Paris)	0
69	cost(Andy,Paris)	0
71	cost(Andy,Paris)	0
72	cost(Andy,Paris)	0
93	cost(Andy,NY)	0
94	cost(Andy,NY)	0
113	cost(Andy,Paris)	0
114	cost(Andy,Paris)	0
117	cost(Andy,NY)	0
118	cost(Andy,NY)	0
123	cost(Andy,Paris)	0
124	cost(Andy,Paris)	0
126	cost(Andy,NY)	0
127	cost(Andy,NY)	1
128	cost(Andy,NY)	0
140	cost(Andy,NY)	0
141	cost(Andy,NY)	1
142	cost(Andy,NY)	0
145	cost(Andy,NY)	0
146	cost(Andy,NY)	1
147	cost(Andy,NY)	0
164	cost(Andy,NY)	0
165	cost(Andy,NY)	0
178	cost(Andy,Paris)	0
179	cost(Andy,Paris)	0
182	cost(Andy,NY)	0
183	cost(Andy,NY)	0
193	cost(Andy,NY)	0
194	cost(Andy,NY)	1
195	cost(Andy,NY)	0
209	cost(Andy,NY)	0
210	cost(Andy,NY)	1
211	cost(Andy,NY)	0
218	cost(Andy,NY)	0
219	cost(Andy,NY)	1
220	cost(Andy,NY)	0
240	cost(Andy,Paris)	0
241	cost(Andy,Paris)	0
243	cost(Andy,NY)	0
244	cost(Andy,NY)	0
256	cost(Andy,NY)	0
257	cost(Andy,NY)	1
258	cost(Andy,NY)	0
277	cost(Andy,NY)	1
278	cost(Andy,NY)	0
\.


--
-- Data for Name: fillrmb_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY fillrmb_params (param_id, state, empl, dest, id_currreq, checked) FROM stdin;
22	4	Andy	Paris	9	t
43	7	Andy	NY	3	t
54	9	Andy	Paris	9	t
89	14	Andy	NY	3	t
119	18	Andy	NY	3	t
120	18	Andy	Paris	9	t
129	19	Andy	Paris	9	t
170	24	Andy	NY	3	t
206	30	Andy	Paris	9	t
213	31	Andy	NY	3	t
224	33	Andy	Paris	9	t
229	34	Andy	NY	3	t
255	38	Andy	NY	3	t
264	39	Andy	NY	3	t
300	44	Andy	NY	3	t
326	50	Andy	Paris	9	t
333	51	Andy	NY	3	t
354	56	Andy	NY	3	t
384	61	Andy	NY	3	t
401	64	Andy	NY	3	t
443	74	Andy	Paris	9	t
448	75	Andy	NY	3	t
473	82	Andy	NY	3	t
514	92	Andy	NY	3	t
\.


--
-- Name: id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('id_seq', 9, true);


--
-- Name: inc_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('inc_seq', 594, true);


--
-- Data for Name: maxamnt_allowed_values; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY maxamnt_allowed_values (value) FROM stdin;
300
\.


--
-- Data for Name: relation_names; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY relation_names (name, readonly) FROM stdin;
Accepted	f
Dest	t
Empl	t
Pending	f
Rejected	f
TrvlCost	f
TrvlMaxAmnt	f
CurrReq	f
\.


--
-- Data for Name: revwreimb_eff_1_eval_res; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY revwreimb_eff_1_eval_res (id_currreq, session_id) FROM stdin;
9	38
3	63
9	80
3	107
3	116
9	120
9	121
9	130
9	131
3	162
3	176
9	177
9	188
3	189
9	190
3	191
9	192
3	205
3	214
3	216
3	230
9	236
3	238
9	248
3	250
9	252
3	254
3	263
3	271
3	275
9	286
3	287
3	290
9	293
3	294
3	303
3	307
\.


--
-- Data for Name: revwreimb_eff_2_eval_res; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY revwreimb_eff_2_eval_res (id_currreq, session_id) FROM stdin;
9	40
9	90
9	144
9	149
9	150
9	152
9	206
3	207
9	208
9	215
9	217
9	225
9	261
9	265
3	267
9	269
9	273
9	297
3	300
9	306
\.


--
-- Data for Name: revwreimb_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY revwreimb_params (param_id, state, cost, id_currreq, checked) FROM stdin;
68	10	0	9	t
72	11	1	9	t
114	16	0	3	t
137	20	0	9	t
152	22	1	9	t
187	27	0	3	t
207	30	0	3	t
214	31	0	9	t
220	32	0	9	t
230	34	0	9	t
238	35	0	9	t
256	38	1	9	t
265	39	1	9	t
273	40	1	9	t
277	41	1	9	t
296	43	0	3	t
322	49	0	3	t
323	49	0	9	t
344	53	0	9	t
346	54	0	3	t
347	54	0	9	t
350	55	1	3	t
351	55	0	9	t
376	59	0	3	t
377	59	1	9	t
380	60	1	3	t
381	60	1	9	t
393	62	0	3	t
394	62	1	9	t
397	63	1	3	t
398	63	1	9	t
414	66	1	9	t
424	69	0	3	t
435	72	0	9	t
439	73	0	3	t
457	78	0	9	t
461	79	0	3	t
465	80	0	9	t
469	81	1	3	t
482	84	1	9	t
486	85	0	3	t
490	86	1	9	t
494	87	1	3	t
498	88	1	9	t
502	89	0	3	t
506	90	1	9	t
510	91	1	3	t
531	98	0	9	t
533	99	0	3	t
539	102	0	3	t
545	104	0	9	t
547	105	1	3	t
553	107	1	9	t
559	109	1	3	t
565	111	0	3	t
571	113	1	9	t
573	114	1	3	t
\.


--
-- Data for Name: rvwreq_maxamnt_service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY rvwreq_maxamnt_service (session_id, service_name, value) FROM stdin;
3	maxamnt(Andy,Paris)	0
4	maxamnt(Andy,Paris)	0
7	maxamnt(Andy,NY)	0
8	maxamnt(Andy,NY)	0
17	maxamnt(Andy,NY)	0
18	maxamnt(Andy,NY)	0
20	maxamnt(Andy,Paris)	0
21	maxamnt(Andy,Paris)	0
29	maxamnt(Andy,NY)	0
30	maxamnt(Andy,NY)	0
31	maxamnt(Andy,NY)	0
32	maxamnt(Andy,NY)	0
41	maxamnt(Andy,NY)	0
42	maxamnt(Andy,NY)	0
43	maxamnt(Andy,NY)	0
44	maxamnt(Andy,NY)	0
48	maxamnt(Andy,Paris)	0
49	maxamnt(Andy,Paris)	0
50	maxamnt(Andy,Paris)	0
51	maxamnt(Andy,Paris)	0
56	maxamnt(Andy,Paris)	0
57	maxamnt(Andy,Paris)	0
58	maxamnt(Andy,Paris)	0
59	maxamnt(Andy,Paris)	0
75	maxamnt(Andy,NY)	0
76	maxamnt(Andy,NY)	1
77	maxamnt(Andy,NY)	0
78	maxamnt(Andy,NY)	1
83	maxamnt(Andy,NY)	0
84	maxamnt(Andy,NY)	1
85	maxamnt(Andy,NY)	0
86	maxamnt(Andy,NY)	0
87	maxamnt(Andy,NY)	1
88	maxamnt(Andy,NY)	0
99	maxamnt(Andy,NY)	0
100	maxamnt(Andy,NY)	0
102	maxamnt(Andy,Paris)	0
103	maxamnt(Andy,Paris)	0
104	maxamnt(Andy,Paris)	0
105	maxamnt(Andy,Paris)	0
108	maxamnt(Andy,Paris)	0
109	maxamnt(Andy,Paris)	0
133	maxamnt(Andy,NY)	0
134	maxamnt(Andy,NY)	0
135	maxamnt(Andy,NY)	0
136	maxamnt(Andy,NY)	0
154	maxamnt(Andy,NY)	0
155	maxamnt(Andy,NY)	1
156	maxamnt(Andy,NY)	0
157	maxamnt(Andy,NY)	0
158	maxamnt(Andy,NY)	1
159	maxamnt(Andy,NY)	0
169	maxamnt(Andy,Paris)	0
170	maxamnt(Andy,Paris)	0
171	maxamnt(Andy,Paris)	0
172	maxamnt(Andy,Paris)	0
200	maxamnt(Andy,NY)	0
201	maxamnt(Andy,NY)	0
202	maxamnt(Andy,NY)	0
203	maxamnt(Andy,NY)	0
231	maxamnt(Andy,Paris)	0
232	maxamnt(Andy,Paris)	0
233	maxamnt(Andy,Paris)	0
234	maxamnt(Andy,Paris)	0
\.


--
-- Data for Name: rvwreq_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY rvwreq_params (param_id, state, empl, dest, id_currreq, checked) FROM stdin;
7	2	Andy	Paris	9	t
14	3	Andy	NY	3	t
32	6	Andy	NY	3	t
33	6	Andy	Paris	9	t
53	9	Andy	NY	3	t
75	12	Andy	NY	3	t
88	14	Andy	Paris	9	t
102	15	Andy	Paris	9	t
136	20	Andy	NY	3	t
151	22	Andy	NY	3	t
181	26	Andy	NY	3	t
186	27	Andy	Paris	9	t
197	28	Andy	Paris	9	t
242	36	Andy	NY	3	t
281	42	Andy	NY	3	t
309	47	Andy	Paris	9	t
367	58	Andy	NY	3	t
426	71	Andy	Paris	9	t
\.


--
-- Data for Name: rvwreq_status_service; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY rvwreq_status_service (session_id, service_name, value) FROM stdin;
3	status(Andy,Paris)	accepted
4	status(Andy,Paris)	rejected
7	status(Andy,NY)	accepted
8	status(Andy,NY)	rejected
17	status(Andy,NY)	accepted
18	status(Andy,NY)	rejected
20	status(Andy,Paris)	accepted
21	status(Andy,Paris)	rejected
29	status(Andy,NY)	accepted
30	status(Andy,NY)	accepted
31	status(Andy,NY)	rejected
32	status(Andy,NY)	rejected
41	status(Andy,NY)	accepted
42	status(Andy,NY)	accepted
43	status(Andy,NY)	rejected
44	status(Andy,NY)	rejected
48	status(Andy,Paris)	accepted
49	status(Andy,Paris)	accepted
50	status(Andy,Paris)	rejected
51	status(Andy,Paris)	rejected
56	status(Andy,Paris)	accepted
57	status(Andy,Paris)	accepted
58	status(Andy,Paris)	rejected
59	status(Andy,Paris)	rejected
75	status(Andy,NY)	accepted
76	status(Andy,NY)	accepted
77	status(Andy,NY)	rejected
78	status(Andy,NY)	rejected
83	status(Andy,NY)	accepted
84	status(Andy,NY)	accepted
85	status(Andy,NY)	accepted
86	status(Andy,NY)	rejected
87	status(Andy,NY)	rejected
88	status(Andy,NY)	rejected
99	status(Andy,NY)	accepted
100	status(Andy,NY)	rejected
102	status(Andy,Paris)	accepted
103	status(Andy,Paris)	accepted
104	status(Andy,Paris)	rejected
105	status(Andy,Paris)	rejected
108	status(Andy,Paris)	accepted
109	status(Andy,Paris)	rejected
133	status(Andy,NY)	accepted
134	status(Andy,NY)	accepted
135	status(Andy,NY)	rejected
136	status(Andy,NY)	rejected
154	status(Andy,NY)	accepted
155	status(Andy,NY)	accepted
156	status(Andy,NY)	accepted
157	status(Andy,NY)	rejected
158	status(Andy,NY)	rejected
159	status(Andy,NY)	rejected
169	status(Andy,Paris)	accepted
170	status(Andy,Paris)	accepted
171	status(Andy,Paris)	rejected
172	status(Andy,Paris)	rejected
200	status(Andy,NY)	accepted
201	status(Andy,NY)	accepted
202	status(Andy,NY)	rejected
203	status(Andy,NY)	rejected
231	status(Andy,Paris)	accepted
232	status(Andy,Paris)	accepted
233	status(Andy,Paris)	rejected
234	status(Andy,Paris)	rejected
\.


--
-- Data for Name: service_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY service_metadata (service, service_return_type, service_fresh_only, service_allowed_values_table, id) FROM stdin;
cost	integer	f		1
status	string	f	status_allowed_values	3
maxamnt	integer	f		2
\.


--
-- Data for Name: startw_params; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY startw_params (param_id, state, empl, dest, checked, pending_id) FROM stdin;
3	1	Andy	Paris	t	9
4	1	Andy	NY	t	3
8	2	Andy	NY	t	3
15	3	Andy	Paris	t	9
21	4	Andy	NY	t	3
28	5	Andy	NY	t	3
42	7	Andy	Paris	t	9
49	8	Andy	Paris	t	9
67	10	Andy	NY	t	3
71	11	Andy	NY	t	3
86	13	Andy	NY	t	3
113	16	Andy	Paris	t	9
117	17	Andy	Paris	t	9
147	21	Andy	NY	t	3
166	23	Andy	NY	t	3
202	29	Andy	Paris	t	9
253	37	Andy	NY	t	3
320	48	Andy	Paris	t	9
\.


--
-- Data for Name: states; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY states (state, "hash_Accepted", "hash_Pending", "hash_Rejected", "hash_TrvlCost", "hash_TrvlMaxAmnt", "hash_CurrReq") FROM stdin;
1	99914b93-2bd3-7a50-b983-c5e7c90ae93b	54682729-657e-5b48-0065-b7388ab1841d	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
2	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	b0a65588-cb07-a69d-6d50-0b4016dec672
3	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	5efcf127-fd4b-3754-1100-d607d4af39ef
4	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	6fbb8885-b2d2-f4a5-671e-82acaf800373
5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	40e65026-834a-cbe0-de05-d1aae96d2a65
6	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d6e3e71c-93a9-6e89-e6f7-2f2e94a9ff93
7	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	1b2a6932-ee02-8f3b-a3c1-80f1eb5c1940
8	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	56eb9ba3-5844-671e-95b7-2f36df671675
9	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	68b90aff-731c-f998-439f-22d91d32212e
10	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
11	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
12	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	7a774720-96ae-98dd-7870-a8508cd5934e
13	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
14	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	1adc2d14-a68d-d367-e259-7fc692e81ff5
15	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	70634375-2599-5d12-23b1-70e17464e7cb
16	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	7012f4cc-6c09-6c97-4217-55161a3338f5
17	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
18	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	2df621c9-668c-c1cf-4b1e-9df7e20c8381
19	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	27ab3440-3079-3002-90eb-7aa6e8a2be97
20	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	85f5f300-f912-e430-29ed-899f069bd9e6
21	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	7741605c-7e0a-1516-6983-9f9819895540
22	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	85f5f300-f912-e430-29ed-899f069bd9e6
23	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	40e65026-834a-cbe0-de05-d1aae96d2a65
24	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	9bbf0b29-b535-111f-fbb3-bb44a8e1d7c0
25	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	e0680d6e-d047-6b87-ed47-86a0a96394fc
26	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	5efcf127-fd4b-3754-1100-d607d4af39ef
27	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	cf3e608f-f3d3-5e5e-864c-5bdfd88ca38a
28	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	b0a65588-cb07-a69d-6d50-0b4016dec672
29	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	bbac6c97-8016-e91e-c77d-409da5b5c98d
30	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	8e7eedc0-3890-c2c9-eced-dde87afdae93	57c96d26-e57a-9d52-2321-acc90a8f26f1
31	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	8e7eedc0-3890-c2c9-eced-dde87afdae93	c053f666-e740-575a-233f-e8d21077bc0f
32	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	8e7eedc0-3890-c2c9-eced-dde87afdae93	e62f1fc4-2c9f-9ad8-2cf3-b90142088f3b
33	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	6fbb8885-b2d2-f4a5-671e-82acaf800373
34	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	df56e422-a0fc-8528-287d-163fd70f5050	c053f666-e740-575a-233f-e8d21077bc0f
35	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	df56e422-a0fc-8528-287d-163fd70f5050	e62f1fc4-2c9f-9ad8-2cf3-b90142088f3b
36	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	60e2cccd-1d60-011c-f7e4-d389abfaaafd
37	809fa040-858f-5b3e-6690-f062a3a75093	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
38	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	8e7eedc0-3890-c2c9-eced-dde87afdae93	c053f666-e740-575a-233f-e8d21077bc0f
39	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	df56e422-a0fc-8528-287d-163fd70f5050	c053f666-e740-575a-233f-e8d21077bc0f
40	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	8e7eedc0-3890-c2c9-eced-dde87afdae93	e62f1fc4-2c9f-9ad8-2cf3-b90142088f3b
41	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	df56e422-a0fc-8528-287d-163fd70f5050	e62f1fc4-2c9f-9ad8-2cf3-b90142088f3b
42	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	7a774720-96ae-98dd-7870-a8508cd5934e
43	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	8e7eedc0-3890-c2c9-eced-dde87afdae93	7a45271e-4566-d5f3-1e88-fe875a7e46a0
44	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	1b2a6932-ee02-8f3b-a3c1-80f1eb5c1940
45	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	40e65026-834a-cbe0-de05-d1aae96d2a65
46	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	56eb9ba3-5844-671e-95b7-2f36df671675
47	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	553478e3-0f04-84fd-cf88-d7d7b6245b1d
48	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
49	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	8e7eedc0-3890-c2c9-eced-dde87afdae93	9cae378e-4207-4d2d-ef6a-5fd70c42dcc1
50	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	8e7eedc0-3890-c2c9-eced-dde87afdae93	977aeab9-c016-7500-1015-440925662171
51	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	8e7eedc0-3890-c2c9-eced-dde87afdae93	bc55ffcc-032b-2b53-425b-3d990833765e
52	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	8e7eedc0-3890-c2c9-eced-dde87afdae93	1e4c8385-6aec-5566-b2d6-0db412b11370
53	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
54	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	df56e422-a0fc-8528-287d-163fd70f5050	9cae378e-4207-4d2d-ef6a-5fd70c42dcc1
55	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	df56e422-a0fc-8528-287d-163fd70f5050	df56e422-a0fc-8528-287d-163fd70f5050	9cae378e-4207-4d2d-ef6a-5fd70c42dcc1
56	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	df56e422-a0fc-8528-287d-163fd70f5050	bc55ffcc-032b-2b53-425b-3d990833765e
57	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	df56e422-a0fc-8528-287d-163fd70f5050	1e4c8385-6aec-5566-b2d6-0db412b11370
58	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	5efcf127-fd4b-3754-1100-d607d4af39ef
59	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	8e7eedc0-3890-c2c9-eced-dde87afdae93	9cae378e-4207-4d2d-ef6a-5fd70c42dcc1
60	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	8e7eedc0-3890-c2c9-eced-dde87afdae93	9cae378e-4207-4d2d-ef6a-5fd70c42dcc1
61	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	8e7eedc0-3890-c2c9-eced-dde87afdae93	9bbf0b29-b535-111f-fbb3-bb44a8e1d7c0
62	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	df56e422-a0fc-8528-287d-163fd70f5050	9cae378e-4207-4d2d-ef6a-5fd70c42dcc1
63	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	df56e422-a0fc-8528-287d-163fd70f5050	9cae378e-4207-4d2d-ef6a-5fd70c42dcc1
64	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	df56e422-a0fc-8528-287d-163fd70f5050	9bbf0b29-b535-111f-fbb3-bb44a8e1d7c0
65	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	8e7eedc0-3890-c2c9-eced-dde87afdae93	e0680d6e-d047-6b87-ed47-86a0a96394fc
66	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
67	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	df56e422-a0fc-8528-287d-163fd70f5050	e0680d6e-d047-6b87-ed47-86a0a96394fc
68	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	8e7eedc0-3890-c2c9-eced-dde87afdae93	c29fe1f8-924e-cfd3-91e2-fa49da053c7f
69	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	7012f4cc-6c09-6c97-4217-55161a3338f5
70	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	b4d69fbe-0319-af3d-de65-8dad418046e1	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
71	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	b0a65588-cb07-a69d-6d50-0b4016dec672
72	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	8e7eedc0-3890-c2c9-eced-dde87afdae93	b25617b6-e8b1-3443-6511-b6611510000f
73	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	8e7eedc0-3890-c2c9-eced-dde87afdae93	4e26ae70-bf50-e5ee-3e1b-8be05a930325
74	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	6fbb8885-b2d2-f4a5-671e-82acaf800373
75	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	1b2a6932-ee02-8f3b-a3c1-80f1eb5c1940
76	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	7741605c-7e0a-1516-6983-9f9819895540
77	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	56eb9ba3-5844-671e-95b7-2f36df671675
78	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	df56e422-a0fc-8528-287d-163fd70f5050	b25617b6-e8b1-3443-6511-b6611510000f
79	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	df56e422-a0fc-8528-287d-163fd70f5050	4e26ae70-bf50-e5ee-3e1b-8be05a930325
80	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	df56e422-a0fc-8528-287d-163fd70f5050	df56e422-a0fc-8528-287d-163fd70f5050	b25617b6-e8b1-3443-6511-b6611510000f
81	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	df56e422-a0fc-8528-287d-163fd70f5050	df56e422-a0fc-8528-287d-163fd70f5050	4e26ae70-bf50-e5ee-3e1b-8be05a930325
82	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	bbc24d44-2083-c427-b04f-428d4c07d601	1b2a6932-ee02-8f3b-a3c1-80f1eb5c1940
83	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	bbc24d44-2083-c427-b04f-428d4c07d601	56eb9ba3-5844-671e-95b7-2f36df671675
84	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	8e7eedc0-3890-c2c9-eced-dde87afdae93	b25617b6-e8b1-3443-6511-b6611510000f
85	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	8e7eedc0-3890-c2c9-eced-dde87afdae93	7a45271e-4566-d5f3-1e88-fe875a7e46a0
86	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	8e7eedc0-3890-c2c9-eced-dde87afdae93	e62f1fc4-2c9f-9ad8-2cf3-b90142088f3b
87	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	8e7eedc0-3890-c2c9-eced-dde87afdae93	7a45271e-4566-d5f3-1e88-fe875a7e46a0
88	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	df56e422-a0fc-8528-287d-163fd70f5050	b25617b6-e8b1-3443-6511-b6611510000f
89	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	df56e422-a0fc-8528-287d-163fd70f5050	7a45271e-4566-d5f3-1e88-fe875a7e46a0
90	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	df56e422-a0fc-8528-287d-163fd70f5050	b25617b6-e8b1-3443-6511-b6611510000f
91	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	df56e422-a0fc-8528-287d-163fd70f5050	7a45271e-4566-d5f3-1e88-fe875a7e46a0
92	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	bbc24d44-2083-c427-b04f-428d4c07d601	1b2a6932-ee02-8f3b-a3c1-80f1eb5c1940
93	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	40e65026-834a-cbe0-de05-d1aae96d2a65
94	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	bbc24d44-2083-c427-b04f-428d4c07d601	56eb9ba3-5844-671e-95b7-2f36df671675
95	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	40e65026-834a-cbe0-de05-d1aae96d2a65
96	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	bbac6c97-8016-e91e-c77d-409da5b5c98d
97	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	8e7eedc0-3890-c2c9-eced-dde87afdae93	42048692-8aaa-9d8d-7b16-6750fea3ffe2
98	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
99	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	7012f4cc-6c09-6c97-4217-55161a3338f5
100	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	be7a6be6-ed2c-403d-9f1c-3c7aa9125195	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
101	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8e7eedc0-3890-c2c9-eced-dde87afdae93	df56e422-a0fc-8528-287d-163fd70f5050	42048692-8aaa-9d8d-7b16-6750fea3ffe2
102	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	bbc24d44-2083-c427-b04f-428d4c07d601	7012f4cc-6c09-6c97-4217-55161a3338f5
103	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	df56e422-a0fc-8528-287d-163fd70f5050	df56e422-a0fc-8528-287d-163fd70f5050	42048692-8aaa-9d8d-7b16-6750fea3ffe2
104	c69508ef-b293-7687-4a8f-7dab1e2a8a84	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
105	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	bbc24d44-2083-c427-b04f-428d4c07d601	bbc24d44-2083-c427-b04f-428d4c07d601	7012f4cc-6c09-6c97-4217-55161a3338f5
106	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	8e7eedc0-3890-c2c9-eced-dde87afdae93	c29fe1f8-924e-cfd3-91e2-fa49da053c7f
107	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
108	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	8e7eedc0-3890-c2c9-eced-dde87afdae93	e0680d6e-d047-6b87-ed47-86a0a96394fc
109	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	bbc24d44-2083-c427-b04f-428d4c07d601	d7680fdc-90c4-8452-5124-0e94b51aebe9	7012f4cc-6c09-6c97-4217-55161a3338f5
110	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	cbf3cbb6-9f95-633b-02f7-eb939be1c6e5	df56e422-a0fc-8528-287d-163fd70f5050	c29fe1f8-924e-cfd3-91e2-fa49da053c7f
111	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	d7680fdc-90c4-8452-5124-0e94b51aebe9	bbc24d44-2083-c427-b04f-428d4c07d601	7012f4cc-6c09-6c97-4217-55161a3338f5
112	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	348cb9d9-277d-23ee-eeaa-45beb216db1a	df56e422-a0fc-8528-287d-163fd70f5050	c29fe1f8-924e-cfd3-91e2-fa49da053c7f
113	c69508ef-b293-7687-4a8f-7dab1e2a8a84	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	cfabe9fb-d081-7856-39a7-474d2bda5e3e
114	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	bbc24d44-2083-c427-b04f-428d4c07d601	bbc24d44-2083-c427-b04f-428d4c07d601	7012f4cc-6c09-6c97-4217-55161a3338f5
115	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
116	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	7741605c-7e0a-1516-6983-9f9819895540
117	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	d7680fdc-90c4-8452-5124-0e94b51aebe9	bbac6c97-8016-e91e-c77d-409da5b5c98d
118	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d7680fdc-90c4-8452-5124-0e94b51aebe9	bbc24d44-2083-c427-b04f-428d4c07d601	bbac6c97-8016-e91e-c77d-409da5b5c98d
119	c69508ef-b293-7687-4a8f-7dab1e2a8a84	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	500da0f4-4885-ab76-808c-b2a25193768d	500da0f4-4885-ab76-808c-b2a25193768d	7741605c-7e0a-1516-6983-9f9819895540
120	809fa040-858f-5b3e-6690-f062a3a75093	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	bbc24d44-2083-c427-b04f-428d4c07d601	bbc24d44-2083-c427-b04f-428d4c07d601	bbac6c97-8016-e91e-c77d-409da5b5c98d
121	8ecdbdd1-4c29-0ff2-c2f3-b2988a7750ed	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	40e65026-834a-cbe0-de05-d1aae96d2a65
122	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	bbc24d44-2083-c427-b04f-428d4c07d601	d7680fdc-90c4-8452-5124-0e94b51aebe9	56eb9ba3-5844-671e-95b7-2f36df671675
123	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	d7680fdc-90c4-8452-5124-0e94b51aebe9	bbc24d44-2083-c427-b04f-428d4c07d601	bbac6c97-8016-e91e-c77d-409da5b5c98d
124	c69508ef-b293-7687-4a8f-7dab1e2a8a84	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	8c271cf6-112a-c72b-b63b-6a657d89f730	500da0f4-4885-ab76-808c-b2a25193768d	40e65026-834a-cbe0-de05-d1aae96d2a65
125	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	bbc24d44-2083-c427-b04f-428d4c07d601	bbc24d44-2083-c427-b04f-428d4c07d601	bbac6c97-8016-e91e-c77d-409da5b5c98d
126	c0a81d87-cefd-c883-8bb0-2e98cc6cdac4	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
127	1a950510-456a-3111-d6eb-e40fe67f2420	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
128	c69508ef-b293-7687-4a8f-7dab1e2a8a84	99914b93-2bd3-7a50-b983-c5e7c90ae93b	d1cca490-4b43-6d58-25d4-e933d974e7f5	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b	99914b93-2bd3-7a50-b983-c5e7c90ae93b
\.


--
-- Data for Name: states_metadata; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY states_metadata (unique_states, recycled_states, collisions_count, deepcheck_success) FROM stdin;
128	104	104	0
\.


--
-- Data for Name: status_allowed_values; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY status_allowed_values (value) FROM stdin;
accepted
rejected
\.


--
-- Name: Accepted_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Accepted"
    ADD CONSTRAINT "Accepted_pkey" PRIMARY KEY (rid, phash);


--
-- Name: CurrReq_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "CurrReq"
    ADD CONSTRAINT "CurrReq_pkey" PRIMARY KEY (rid, phash);


--
-- Name: Dest_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Dest"
    ADD CONSTRAINT "Dest_pkey" PRIMARY KEY (id);


--
-- Name: Empl_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Empl"
    ADD CONSTRAINT "Empl_pkey" PRIMARY KEY (id);


--
-- Name: Pending_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Pending"
    ADD CONSTRAINT "Pending_pkey" PRIMARY KEY (rid, phash);


--
-- Name: Rejected_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Rejected"
    ADD CONSTRAINT "Rejected_pkey" PRIMARY KEY (rid, phash);


--
-- Name: TS_enabled_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TS_enabled"
    ADD CONSTRAINT "TS_enabled_pkey" PRIMARY KEY (id);


--
-- Name: TS_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TS"
    ADD CONSTRAINT "TS_pkey" PRIMARY KEY (curr, next);


--
-- Name: TrvlCost_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TrvlCost"
    ADD CONSTRAINT "TrvlCost_pkey" PRIMARY KEY (rid, phash);


--
-- Name: TrvlMaxAmnt_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TrvlMaxAmnt"
    ADD CONSTRAINT "TrvlMaxAmnt_pkey" PRIMARY KEY (rid, phash);


--
-- Name: accepted_state_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Accepted_state_log"
    ADD CONSTRAINT accepted_state_log_pkey PRIMARY KEY (state, id);


--
-- Name: action_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY action_metadata
    ADD CONSTRAINT action_metadata_pkey PRIMARY KEY (id);


--
-- Name: current_state_copy_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY current_session_id
    ADD CONSTRAINT current_state_copy_pkey PRIMARY KEY (id);


--
-- Name: current_state_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY current_state
    ADD CONSTRAINT current_state_pkey PRIMARY KEY (id);


--
-- Name: currreq_state_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "CurrReq_state_log"
    ADD CONSTRAINT currreq_state_log_pkey PRIMARY KEY (state, id);


--
-- Name: endw_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY endw_params
    ADD CONSTRAINT endw_params_pkey PRIMARY KEY (param_id);


--
-- Name: endw_unique_params; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY endw_params
    ADD CONSTRAINT endw_unique_params UNIQUE (state, empl, dest, status, id_currreq);


--
-- Name: fillrmb_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY fillrmb_params
    ADD CONSTRAINT fillrmb_params_pkey PRIMARY KEY (param_id);


--
-- Name: fillrmb_unique_params; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY fillrmb_params
    ADD CONSTRAINT fillrmb_unique_params UNIQUE (state, empl, dest, id_currreq);


--
-- Name: maxamnt_allowed_values_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY maxamnt_allowed_values
    ADD CONSTRAINT maxamnt_allowed_values_pkey PRIMARY KEY (value);


--
-- Name: pending_state_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Pending_state_log"
    ADD CONSTRAINT pending_state_log_pkey PRIMARY KEY (state, id);


--
-- Name: pk_dest; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Dest"
    ADD CONSTRAINT pk_dest UNIQUE (dest) DEFERRABLE;


--
-- Name: pk_empl; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Empl"
    ADD CONSTRAINT pk_empl UNIQUE (empl) DEFERRABLE;


--
-- Name: pk_pending; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Pending"
    ADD CONSTRAINT pk_pending UNIQUE (empl, dest) DEFERRABLE;


--
-- Name: rejected_state_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Rejected_state_log"
    ADD CONSTRAINT rejected_state_log_pkey PRIMARY KEY (state, id);


--
-- Name: relation_names_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY relation_names
    ADD CONSTRAINT relation_names_pkey PRIMARY KEY (name);


--
-- Name: revwreimb_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY revwreimb_params
    ADD CONSTRAINT revwreimb_params_pkey PRIMARY KEY (param_id);


--
-- Name: rvwreq_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY rvwreq_params
    ADD CONSTRAINT rvwreq_params_pkey PRIMARY KEY (param_id);


--
-- Name: rvwreq_unique_params; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY rvwreq_params
    ADD CONSTRAINT rvwreq_unique_params UNIQUE (state, empl, dest, id_currreq);


--
-- Name: service_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY service_metadata
    ADD CONSTRAINT service_metadata_pkey PRIMARY KEY (id);


--
-- Name: startw_params_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY startw_params
    ADD CONSTRAINT startw_params_pkey PRIMARY KEY (param_id);


--
-- Name: startw_unique_params; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY startw_params
    ADD CONSTRAINT startw_unique_params UNIQUE (state, empl, dest);


--
-- Name: states_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY states
    ADD CONSTRAINT states_pkey PRIMARY KEY (state);


--
-- Name: status_accepted_values_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY status_allowed_values
    ADD CONSTRAINT status_accepted_values_pkey PRIMARY KEY (value);


--
-- Name: trvlcost_state_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TrvlCost_state_log"
    ADD CONSTRAINT trvlcost_state_log_pkey PRIMARY KEY (state, fid);


--
-- Name: trvlmaxamnt_state_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TrvlMaxAmnt_state_log"
    ADD CONSTRAINT trvlmaxamnt_state_log_pkey PRIMARY KEY (state, fid);


--
-- Name: unique_currreq_rid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "CurrReq"
    ADD CONSTRAINT unique_currreq_rid UNIQUE (rid);


--
-- Name: unqiue_accepted_rid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Accepted"
    ADD CONSTRAINT unqiue_accepted_rid UNIQUE (rid);


--
-- Name: unqiue_pending_rid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Pending"
    ADD CONSTRAINT unqiue_pending_rid UNIQUE (rid);


--
-- Name: unqiue_rejected_rid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "Rejected"
    ADD CONSTRAINT unqiue_rejected_rid UNIQUE (rid);


--
-- Name: unqiue_trvlcost_rid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TrvlCost"
    ADD CONSTRAINT unqiue_trvlcost_rid UNIQUE (rid);


--
-- Name: unqiue_trvlmaxamnt_rid; Type: CONSTRAINT; Schema: public; Owner: postgres; Tablespace: 
--

ALTER TABLE ONLY "TrvlMaxAmnt"
    ADD CONSTRAINT unqiue_trvlmaxamnt_rid UNIQUE (rid);


--
-- Name: CurrReq_rid_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX "CurrReq_rid_key" ON "CurrReq" USING btree (rid);


--
-- Name: Dest_dest_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX "Dest_dest_key" ON "Dest" USING btree (dest);


--
-- Name: Empl_empl_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX "Empl_empl_key" ON "Empl" USING btree (empl);


--
-- Name: Pending_empl_dest_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX "Pending_empl_dest_key" ON "Pending" USING btree (empl, dest);


--
-- Name: accepted_endw_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX accepted_endw_key ON "Accepted_endw_dump" USING hash (session_id);


--
-- Name: accepted_endw_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX accepted_endw_state_log_key ON "Accepted_endw_state_log_dump" USING hash (session_id);


--
-- Name: accepted_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX accepted_state_log_key ON "Accepted_state_log_dump" USING hash (state);


--
-- Name: currreq_endw_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_endw_state_log_key ON "CurrReq_endw_state_log_dump" USING hash (session_id);


--
-- Name: currreq_fillrmb_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_fillrmb_key ON "CurrReq_fillrmb_dump" USING hash (session_id);


--
-- Name: currreq_fillrmb_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_fillrmb_state_log_key ON "CurrReq_fillrmb_state_log_dump" USING hash (session_id);


--
-- Name: currreq_revwreimb_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_revwreimb_key ON "CurrReq_revwreimb_dump" USING hash (session_id);


--
-- Name: currreq_revwreimb_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_revwreimb_state_log_key ON "CurrReq_revwreimb_state_log_dump" USING hash (session_id);


--
-- Name: currreq_rvwreq_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_rvwreq_key ON "CurrReq_rvwreq_dump" USING hash (session_id);


--
-- Name: currreq_rvwreq_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_rvwreq_state_log_key ON "CurrReq_rvwreq_state_log_dump" USING hash (session_id);


--
-- Name: currreq_startw_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_startw_key ON "CurrReq_startw_dump" USING hash (session_id);


--
-- Name: currreq_startw_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX currreq_startw_state_log_key ON "CurrReq_startw_state_log_dump" USING hash (session_id);


--
-- Name: endw_eff_1_eval_res_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX endw_eff_1_eval_res_key ON endw_eff_1_eval_res USING hash (session_id);


--
-- Name: endw_eff_2_eval_res_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX endw_eff_2_eval_res_key ON endw_eff_2_eval_res USING hash (session_id);


--
-- Name: fillrmb_cost_service_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX fillrmb_cost_service_key ON fillrmb_cost_service USING hash (session_id);


--
-- Name: pending_startw_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX pending_startw_state_log_key ON "Pending_startw_state_log_dump" USING hash (session_id);


--
-- Name: rejected_endw_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX rejected_endw_key ON "Rejected_endw_dump" USING hash (session_id);


--
-- Name: rejected_endw_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX rejected_endw_state_log_key ON "Rejected_endw_state_log_dump" USING hash (session_id);


--
-- Name: revwreimb_eff_1_eval_res_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX revwreimb_eff_1_eval_res_key ON revwreimb_eff_1_eval_res USING hash (session_id);


--
-- Name: revwreimb_eff_2_eval_res_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX revwreimb_eff_2_eval_res_key ON revwreimb_eff_2_eval_res USING hash (session_id);


--
-- Name: rvwreq_maxamnt_service_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX rvwreq_maxamnt_service_key ON rvwreq_maxamnt_service USING hash (session_id);


--
-- Name: rvwreq_status_service_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX rvwreq_status_service_key ON rvwreq_status_service USING hash (session_id);


--
-- Name: service_metadata_id_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE UNIQUE INDEX service_metadata_id_key ON service_metadata USING btree (id);


--
-- Name: trvlcost_endw_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX trvlcost_endw_state_log_key ON "TrvlCost_endw_state_log_dump" USING hash (session_id);


--
-- Name: trvlcost_fillrmb_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX trvlcost_fillrmb_key ON "TrvlCost_fillrmb_dump" USING hash (session_id);


--
-- Name: trvlcost_fillrmb_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX trvlcost_fillrmb_state_log_key ON "TrvlCost_fillrmb_state_log_dump" USING hash (session_id);


--
-- Name: trvlmaxamnt_endw_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX trvlmaxamnt_endw_state_log_key ON "TrvlMaxAmnt_endw_state_log_dump" USING hash (session_id);


--
-- Name: trvlmaxamnt_rvwreq_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX trvlmaxamnt_rvwreq_key ON "TrvlMaxAmnt_rvwreq_dump" USING hash (session_id);


--
-- Name: trvlmaxamnt_rvwreq_state_log_key; Type: INDEX; Schema: public; Owner: postgres; Tablespace: 
--

CREATE INDEX trvlmaxamnt_rvwreq_state_log_key ON "TrvlMaxAmnt_rvwreq_state_log_dump" USING hash (session_id);


--
-- Name: stability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER stability BEFORE DELETE ON current_state FOR EACH ROW EXECUTE PROCEDURE no_delete();


--
-- Name: stability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER stability BEFORE DELETE ON "TS_enabled" FOR EACH ROW EXECUTE PROCEDURE no_delete();


--
-- Name: stability; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER stability BEFORE DELETE ON current_session_id FOR EACH ROW EXECUTE PROCEDURE no_delete();


--
-- Name: unique_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unique_id AFTER INSERT OR UPDATE ON current_state FOR EACH ROW EXECUTE PROCEDURE check_uniqueness();


--
-- Name: unique_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unique_id AFTER INSERT OR UPDATE ON "TS_enabled" FOR EACH ROW EXECUTE PROCEDURE check_uniqueness();


--
-- Name: unique_id; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER unique_id AFTER INSERT OR UPDATE ON current_session_id FOR EACH ROW EXECUTE PROCEDURE check_uniqueness();


--
-- Name: fk_TrvlCost_CurrReq; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "TrvlCost_state_log"
    ADD CONSTRAINT "fk_TrvlCost_CurrReq" FOREIGN KEY (state, fid) REFERENCES "CurrReq_state_log"(state, id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: fk_TrvlMaxAmnt_CurrReq; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "TrvlMaxAmnt_state_log"
    ADD CONSTRAINT "fk_TrvlMaxAmnt_CurrReq" FOREIGN KEY (state, fid) REFERENCES "CurrReq_state_log"(state, id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: fk_service; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY action_metadata
    ADD CONSTRAINT fk_service FOREIGN KEY (service) REFERENCES service_metadata(id);


--
-- Name: pending_dest_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Pending"
    ADD CONSTRAINT pending_dest_fk FOREIGN KEY (dest) REFERENCES "Dest"(dest) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: pending_empl_fk; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Pending"
    ADD CONSTRAINT pending_empl_fk FOREIGN KEY (empl) REFERENCES "Empl"(empl) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


--
-- Name: ref_Accepted; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Accepted_state_log"
    ADD CONSTRAINT "ref_Accepted" FOREIGN KEY (rid) REFERENCES "Accepted"(rid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ref_CurrReq; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "CurrReq_state_log"
    ADD CONSTRAINT "ref_CurrReq" FOREIGN KEY (rid) REFERENCES "CurrReq"(rid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ref_Pending; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Pending_state_log"
    ADD CONSTRAINT "ref_Pending" FOREIGN KEY (rid) REFERENCES "Pending"(rid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ref_Rejected; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Rejected_state_log"
    ADD CONSTRAINT "ref_Rejected" FOREIGN KEY (rid) REFERENCES "Rejected"(rid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ref_TrvlCost; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "TrvlCost_state_log"
    ADD CONSTRAINT "ref_TrvlCost" FOREIGN KEY (rid) REFERENCES "TrvlCost"(rid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ref_TrvlMaxAmnt; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "TrvlMaxAmnt_state_log"
    ADD CONSTRAINT "ref_TrvlMaxAmnt" FOREIGN KEY (rid) REFERENCES "TrvlMaxAmnt"(rid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

