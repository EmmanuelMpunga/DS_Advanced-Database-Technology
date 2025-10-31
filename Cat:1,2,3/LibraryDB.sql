MPUNGA EMMANUEL 
Reg No: 224019555
African Centre of Excellence in Data Science (ACE-DS)
Masters of Data Science in Mining
UR-CBE Gikondo Campus
Module: Advanced Database and Technology

\restrict mkzigh4SSYTVFvFrW6WaNXMOhaq0zgfflzwcNZ9ZaB5c6kGIh2wjRPddYjrulKj

-- Dumped from database version 18.0
-- Dumped by pg_dump version 18.0

-- Started on 2025-10-31 16:08:50

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 16744)
-- Name: customers; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA customers;


ALTER SCHEMA customers OWNER TO postgres;

--
-- TOC entry 7 (class 2615 OID 16715)
-- Name: sales; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA sales;


ALTER SCHEMA sales OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 16763)
-- Name: postgres_fdw; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgres_fdw WITH SCHEMA public;


--
-- TOC entry 5140 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgres_fdw; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgres_fdw IS 'foreign-data wrapper for remote PostgreSQL servers';


--
-- TOC entry 260 (class 1255 OID 16845)
-- Name: fn_should_alert(character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_should_alert(rule_key_input character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_threshold NUMERIC;
    v_max_amount NUMERIC;
BEGIN
    -- Get the active threshold for the rule
    SELECT threshold
    INTO v_threshold
    FROM business_limits
    WHERE rule_key = rule_key_input
      AND active = 'Y';

    -- Get the current maximum value from Fine table
    SELECT COALESCE(MAX(amount),0)
    INTO v_max_amount
    FROM fine;

    -- Compare and return
    IF v_max_amount > v_threshold THEN
        RETURN 1; -- violation
    ELSE
        RETURN 0; -- no violation
    END IF;
END;
$$;


ALTER FUNCTION public.fn_should_alert(rule_key_input character varying) OWNER TO postgres;

--
-- TOC entry 258 (class 1255 OID 16827)
-- Name: recompute_borrow_totals(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.recompute_borrow_totals() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Update Borrow totals based on current Fine table
    UPDATE borrow b
    SET total_fines = COALESCE(ft.total_amount, 0)
    FROM (
        SELECT borrowid, SUM(amount) AS total_amount
        FROM fine
        GROUP BY borrowid
    ) AS ft
    WHERE b.borrowid = ft.borrowid;

    -- For Borrow rows with no fines, set total_fines to 0
    UPDATE borrow
    SET total_fines = 0
    WHERE borrowid NOT IN (SELECT DISTINCT borrowid FROM fine);

    RETURN NULL;  -- statement-level triggers return NULL
END;
$$;


ALTER FUNCTION public.recompute_borrow_totals() OWNER TO postgres;

--
-- TOC entry 259 (class 1255 OID 16828)
-- Name: trg_fine_audit_totals(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_fine_audit_totals() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_bef_total NUMERIC;
    v_aft_total NUMERIC;
BEGIN
    -- Compute total fines before the statement
    SELECT COALESCE(SUM(amount), 0) INTO v_bef_total FROM Fine;

    -- Recompute denormalized totals for each borrow
    UPDATE Borrow b
    SET total_fines = (
        SELECT COALESCE(SUM(f.amount), 0)
        FROM Fine f
        WHERE f.borrowid = b.borrowid
    );

    -- Compute total fines after the update
    SELECT COALESCE(SUM(amount), 0) INTO v_aft_total FROM Fine;

    -- Insert audit log
    INSERT INTO Borrow_AUDIT(bef_total, aft_total, changed_at, key_col)
    VALUES (v_bef_total, v_aft_total, CURRENT_TIMESTAMP, TG_OP);

    RETURN NULL;  -- statement-level triggers return null
END;
$$;


ALTER FUNCTION public.trg_fine_audit_totals() OWNER TO postgres;

--
-- TOC entry 261 (class 1255 OID 16846)
-- Name: trg_fine_business_limit(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trg_fine_business_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Call the business rule function
    IF fn_should_alert('MAX_FINE_AMOUNT') = 1 THEN
        RAISE EXCEPTION 'Business rule violated: Fine amount exceeds threshold!';
    END IF;

    RETURN NEW; -- required for BEFORE triggers
END;
$$;


ALTER FUNCTION public.trg_fine_business_limit() OWNER TO postgres;

--
-- TOC entry 2157 (class 1417 OID 16771)
-- Name: node_b_server; Type: SERVER; Schema: -; Owner: postgres
--

CREATE SERVER node_b_server FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'your_db',
    host 'node_b_host',
    port '5432'
);


ALTER SERVER node_b_server OWNER TO postgres;

--
-- TOC entry 5141 (class 0 OID 0)
-- Name: USER MAPPING postgres SERVER node_b_server; Type: USER MAPPING; Schema: -; Owner: postgres
--

CREATE USER MAPPING FOR postgres SERVER node_b_server OPTIONS (
    password '123456',
    "user" 'postgres'
);


--
-- TOC entry 2158 (class 1417 OID 16780)
-- Name: proj_link; Type: SERVER; Schema: -; Owner: postgres
--

CREATE SERVER proj_link FOREIGN DATA WRAPPER postgres_fdw OPTIONS (
    dbname 'node_b_db',
    host 'NODE_B_HOST_OR_IP',
    port '5432'
);


ALTER SERVER proj_link OWNER TO postgres;

--
-- TOC entry 5142 (class 0 OID 0)
-- Name: USER MAPPING postgres SERVER proj_link; Type: USER MAPPING; Schema: -; Owner: postgres
--

CREATE USER MAPPING FOR postgres SERVER proj_link OPTIONS (
    password 'your_password',
    "user" 'postgres'
);


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 16642)
-- Name: author; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.author (
    authorid integer NOT NULL,
    fullname character varying(100),
    nationality character varying(50),
    birthyear integer
);


ALTER TABLE public.author OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16641)
-- Name: author_authorid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.author_authorid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.author_authorid_seq OWNER TO postgres;

--
-- TOC entry 5143 (class 0 OID 0)
-- Dependencies: 222
-- Name: author_authorid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.author_authorid_seq OWNED BY public.author.authorid;


--
-- TOC entry 225 (class 1259 OID 16650)
-- Name: book; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.book (
    bookid integer NOT NULL,
    title character varying(100),
    authorid integer,
    genre character varying(50),
    publicationyear integer,
    status character varying(20)
);


ALTER TABLE public.book OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16649)
-- Name: book_bookid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.book_bookid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.book_bookid_seq OWNER TO postgres;

--
-- TOC entry 5144 (class 0 OID 0)
-- Dependencies: 224
-- Name: book_bookid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.book_bookid_seq OWNED BY public.book.bookid;


--
-- TOC entry 244 (class 1259 OID 16782)
-- Name: book_fdw; Type: FOREIGN TABLE; Schema: public; Owner: postgres
--

CREATE FOREIGN TABLE public.book_fdw (
    book_id integer,
    title text,
    author_id integer,
    published_year integer
)
SERVER proj_link
OPTIONS (
    schema_name 'public',
    table_name 'book'
);


ALTER FOREIGN TABLE public.book_fdw OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 16785)
-- Name: book_fdw2; Type: FOREIGN TABLE; Schema: public; Owner: postgres
--

CREATE FOREIGN TABLE public.book_fdw2 (
    book_id integer,
    title text,
    author_id integer,
    published_year integer
)
SERVER proj_link
OPTIONS (
    schema_name 'public',
    table_name 'book'
);


ALTER FOREIGN TABLE public.book_fdw2 OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16679)
-- Name: borrow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.borrow (
    borrowid integer NOT NULL,
    bookid integer NOT NULL,
    memberid integer NOT NULL,
    staffid integer NOT NULL,
    borrowdate date NOT NULL,
    duedate date NOT NULL,
    returndate date,
    CONSTRAINT chk_duedate CHECK ((duedate >= borrowdate)),
    CONSTRAINT chk_returndate CHECK (((returndate >= borrowdate) AND (returndate <= CURRENT_DATE)))
);


ALTER TABLE public.borrow OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 16757)
-- Name: borrow_a; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.borrow_a (
    borrowid integer,
    bookid integer,
    memberid integer,
    staffid integer,
    borrowdate date,
    duedate date,
    returndate date
);


ALTER TABLE public.borrow_a OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 16794)
-- Name: borrow_a_fdw; Type: FOREIGN TABLE; Schema: public; Owner: postgres
--

CREATE FOREIGN TABLE public.borrow_a_fdw (
    borrow_id integer,
    book_id integer,
    member_id integer,
    borrow_date date,
    return_date date
)
SERVER proj_link
OPTIONS (
    schema_name 'public',
    table_name 'borrow_a'
);


ALTER FOREIGN TABLE public.borrow_a_fdw OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 16760)
-- Name: borrow_b; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.borrow_b (
    borrowid integer,
    bookid integer,
    memberid integer,
    staffid integer,
    borrowdate date,
    duedate date,
    returndate date
);


ALTER TABLE public.borrow_b OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 16776)
-- Name: borrow_all; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.borrow_all AS
 SELECT borrow_a.borrowid,
    borrow_a.bookid,
    borrow_a.memberid,
    borrow_a.staffid,
    borrow_a.borrowdate,
    borrow_a.duedate,
    borrow_a.returndate
   FROM public.borrow_a
UNION ALL
 SELECT borrow_b.borrowid,
    borrow_b.bookid,
    borrow_b.memberid,
    borrow_b.staffid,
    borrow_b.borrowdate,
    borrow_b.duedate,
    borrow_b.returndate
   FROM public.borrow_b;


ALTER VIEW public.borrow_all OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 16821)
-- Name: borrow_audit; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.borrow_audit (
    bef_total numeric,
    aft_total numeric,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    key_col character varying(64)
);


ALTER TABLE public.borrow_audit OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 16773)
-- Name: borrow_b_fdw; Type: FOREIGN TABLE; Schema: public; Owner: postgres
--

CREATE FOREIGN TABLE public.borrow_b_fdw (
    borrow_id integer,
    book_id integer,
    member_id integer,
    borrow_date date,
    return_date date
)
SERVER node_b_server
OPTIONS (
    schema_name 'public',
    table_name 'borrow_b'
);


ALTER FOREIGN TABLE public.borrow_b_fdw OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16678)
-- Name: borrow_borrowid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.borrow_borrowid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.borrow_borrowid_seq OWNER TO postgres;

--
-- TOC entry 5145 (class 0 OID 0)
-- Dependencies: 230
-- Name: borrow_borrowid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.borrow_borrowid_seq OWNED BY public.borrow.borrowid;


--
-- TOC entry 252 (class 1259 OID 16839)
-- Name: business_limits; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.business_limits (
    rule_key character varying(64),
    threshold numeric,
    active character(1),
    CONSTRAINT business_limits_active_check CHECK ((active = ANY (ARRAY['Y'::bpchar, 'N'::bpchar])))
);


ALTER TABLE public.business_limits OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16703)
-- Name: fine; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fine (
    fineid integer NOT NULL,
    borrowid integer,
    amount numeric(10,2),
    paymentdate date,
    status character varying(20)
);


ALTER TABLE public.fine OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 16791)
-- Name: fine_fdw; Type: FOREIGN TABLE; Schema: public; Owner: postgres
--

CREATE FOREIGN TABLE public.fine_fdw (
    fine_id integer,
    borrow_id integer,
    amount numeric,
    paid_status character(1)
)
SERVER proj_link
OPTIONS (
    schema_name 'public',
    table_name 'fine'
);


ALTER FOREIGN TABLE public.fine_fdw OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16702)
-- Name: fine_fineid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fine_fineid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fine_fineid_seq OWNER TO postgres;

--
-- TOC entry 5146 (class 0 OID 0)
-- Dependencies: 232
-- Name: fine_fineid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fine_fineid_seq OWNED BY public.fine.fineid;


--
-- TOC entry 250 (class 1259 OID 16829)
-- Name: hier; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hier (
    parent_id character varying(20) NOT NULL,
    child_id character varying(20) NOT NULL
);


ALTER TABLE public.hier OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16663)
-- Name: member; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.member (
    memberid integer NOT NULL,
    fullname character varying(100),
    contact character varying(20),
    address character varying(150),
    email character varying(100)
);


ALTER TABLE public.member OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 16788)
-- Name: member_fdw; Type: FOREIGN TABLE; Schema: public; Owner: postgres
--

CREATE FOREIGN TABLE public.member_fdw (
    member_id integer,
    name text,
    membership_date date
)
SERVER proj_link
OPTIONS (
    schema_name 'public',
    table_name 'member'
);


ALTER FOREIGN TABLE public.member_fdw OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16662)
-- Name: member_memberid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.member_memberid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.member_memberid_seq OWNER TO postgres;

--
-- TOC entry 5147 (class 0 OID 0)
-- Dependencies: 226
-- Name: member_memberid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.member_memberid_seq OWNED BY public.member.memberid;


--
-- TOC entry 229 (class 1259 OID 16671)
-- Name: staff; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff (
    staffid integer NOT NULL,
    fullname character varying(100),
    role character varying(50),
    phone character varying(20),
    shift character varying(20)
);


ALTER TABLE public.staff OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16670)
-- Name: staff_staffid_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.staff_staffid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_staffid_seq OWNER TO postgres;

--
-- TOC entry 5148 (class 0 OID 0)
-- Dependencies: 228
-- Name: staff_staffid_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.staff_staffid_seq OWNED BY public.staff.staffid;


--
-- TOC entry 251 (class 1259 OID 16836)
-- Name: triple; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.triple (
    s character varying(64),
    p character varying(64),
    o character varying(64)
);


ALTER TABLE public.triple OWNER TO postgres;

--
-- TOC entry 239 (class 1259 OID 16746)
-- Name: clients; Type: TABLE; Schema: sales; Owner: postgres
--

CREATE TABLE sales.clients (
    client_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50),
    email character varying(100),
    phone character varying(20),
    registered_date date DEFAULT CURRENT_DATE
);


ALTER TABLE sales.clients OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 16745)
-- Name: clients_client_id_seq; Type: SEQUENCE; Schema: sales; Owner: postgres
--

CREATE SEQUENCE sales.clients_client_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE sales.clients_client_id_seq OWNER TO postgres;

--
-- TOC entry 5149 (class 0 OID 0)
-- Dependencies: 238
-- Name: clients_client_id_seq; Type: SEQUENCE OWNED BY; Schema: sales; Owner: postgres
--

ALTER SEQUENCE sales.clients_client_id_seq OWNED BY sales.clients.client_id;


--
-- TOC entry 235 (class 1259 OID 16717)
-- Name: customers; Type: TABLE; Schema: sales; Owner: postgres
--

CREATE TABLE sales.customers (
    customer_id integer NOT NULL,
    name text NOT NULL,
    email text,
    joined_date date DEFAULT CURRENT_DATE
);


ALTER TABLE sales.customers OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 16716)
-- Name: customers_customer_id_seq; Type: SEQUENCE; Schema: sales; Owner: postgres
--

CREATE SEQUENCE sales.customers_customer_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE sales.customers_customer_id_seq OWNER TO postgres;

--
-- TOC entry 5150 (class 0 OID 0)
-- Dependencies: 234
-- Name: customers_customer_id_seq; Type: SEQUENCE OWNED BY; Schema: sales; Owner: postgres
--

ALTER SEQUENCE sales.customers_customer_id_seq OWNED BY sales.customers.customer_id;


--
-- TOC entry 237 (class 1259 OID 16731)
-- Name: orders; Type: TABLE; Schema: sales; Owner: postgres
--

CREATE TABLE sales.orders (
    order_id integer NOT NULL,
    customer_id integer,
    order_date date DEFAULT CURRENT_DATE,
    amount numeric(10,2)
);


ALTER TABLE sales.orders OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 16730)
-- Name: orders_order_id_seq; Type: SEQUENCE; Schema: sales; Owner: postgres
--

CREATE SEQUENCE sales.orders_order_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE sales.orders_order_id_seq OWNER TO postgres;

--
-- TOC entry 5151 (class 0 OID 0)
-- Dependencies: 236
-- Name: orders_order_id_seq; Type: SEQUENCE OWNED BY; Schema: sales; Owner: postgres
--

ALTER SEQUENCE sales.orders_order_id_seq OWNED BY sales.orders.order_id;


--
-- TOC entry 4916 (class 2604 OID 16645)
-- Name: author authorid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.author ALTER COLUMN authorid SET DEFAULT nextval('public.author_authorid_seq'::regclass);


--
-- TOC entry 4917 (class 2604 OID 16653)
-- Name: book bookid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book ALTER COLUMN bookid SET DEFAULT nextval('public.book_bookid_seq'::regclass);


--
-- TOC entry 4920 (class 2604 OID 16682)
-- Name: borrow borrowid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrow ALTER COLUMN borrowid SET DEFAULT nextval('public.borrow_borrowid_seq'::regclass);


--
-- TOC entry 4921 (class 2604 OID 16706)
-- Name: fine fineid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fine ALTER COLUMN fineid SET DEFAULT nextval('public.fine_fineid_seq'::regclass);


--
-- TOC entry 4918 (class 2604 OID 16666)
-- Name: member memberid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member ALTER COLUMN memberid SET DEFAULT nextval('public.member_memberid_seq'::regclass);


--
-- TOC entry 4919 (class 2604 OID 16674)
-- Name: staff staffid; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff ALTER COLUMN staffid SET DEFAULT nextval('public.staff_staffid_seq'::regclass);


--
-- TOC entry 4926 (class 2604 OID 16749)
-- Name: clients client_id; Type: DEFAULT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.clients ALTER COLUMN client_id SET DEFAULT nextval('sales.clients_client_id_seq'::regclass);


--
-- TOC entry 4922 (class 2604 OID 16720)
-- Name: customers customer_id; Type: DEFAULT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.customers ALTER COLUMN customer_id SET DEFAULT nextval('sales.customers_customer_id_seq'::regclass);


--
-- TOC entry 4924 (class 2604 OID 16734)
-- Name: orders order_id; Type: DEFAULT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.orders ALTER COLUMN order_id SET DEFAULT nextval('sales.orders_order_id_seq'::regclass);


--
-- TOC entry 5112 (class 0 OID 16642)
-- Dependencies: 223
-- Data for Name: author; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.author (authorid, fullname, nationality, birthyear) FROM stdin;
2	Wole Soyinka	Nigerian	1934
3	Chimamanda Ngozi Adichie	Nigerian	1977
5	George Orwell	British	1903
6	Gabriel García Márquez	Colombian	1927
7	Jane Austen	British	1775
8	Mark Twain	American	1835
1	Leo Tolstoy	Russian	1828
\.


--
-- TOC entry 5114 (class 0 OID 16650)
-- Dependencies: 225
-- Data for Name: book; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.book (bookid, title, authorid, genre, publicationyear, status) FROM stdin;
1	The Stranger	2	Philosophical Fiction	1942	Available
2	One Hundred Years of Solitude	2	Magical Realism	1967	Available
3	Pride and Prejudice	3	Romance	1813	Available
4	Adventures of Huckleberry Finn	5	Adventure	1884	Available
5	War and Peace	1	Historical Fiction	1869	Available
\.


--
-- TOC entry 5120 (class 0 OID 16679)
-- Dependencies: 231
-- Data for Name: borrow; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.borrow (borrowid, bookid, memberid, staffid, borrowdate, duedate, returndate) FROM stdin;
1	1	3	2	2025-10-01	2025-10-15	2025-10-10
2	2	1	4	2025-10-04	2025-10-18	\N
3	4	6	3	2025-10-05	2025-10-19	2025-10-18
4	5	2	5	2025-10-06	2025-10-20	\N
\.


--
-- TOC entry 5129 (class 0 OID 16757)
-- Dependencies: 240
-- Data for Name: borrow_a; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.borrow_a (borrowid, bookid, memberid, staffid, borrowdate, duedate, returndate) FROM stdin;
1	1	3	2	2025-10-01	2025-10-15	2025-10-10
2	2	1	4	2025-10-04	2025-10-18	\N
3	4	6	3	2025-10-05	2025-10-19	2025-10-18
4	5	2	5	2025-10-06	2025-10-20	\N
1	101	201	\N	2025-10-01	\N	2025-10-10
2	102	202	\N	2025-10-02	\N	2025-10-12
3	103	203	\N	2025-10-03	\N	2025-10-13
4	104	204	\N	2025-10-04	\N	2025-10-14
5	105	205	\N	2025-10-05	\N	2025-10-15
11	111	211	\N	2025-10-28	\N	2025-11-07
11	111	211	\N	2025-10-28	\N	2025-11-07
12	112	212	\N	2025-10-28	\N	2025-11-07
\.


--
-- TOC entry 5131 (class 0 OID 16821)
-- Dependencies: 249
-- Data for Name: borrow_audit; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.borrow_audit (bef_total, aft_total, changed_at, key_col) FROM stdin;
\.


--
-- TOC entry 5130 (class 0 OID 16760)
-- Dependencies: 241
-- Data for Name: borrow_b; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.borrow_b (borrowid, bookid, memberid, staffid, borrowdate, duedate, returndate) FROM stdin;
6	106	206	\N	2025-10-06	\N	2025-10-16
7	107	207	\N	2025-10-07	\N	2025-10-17
8	108	208	\N	2025-10-08	\N	2025-10-18
9	109	209	\N	2025-10-09	\N	2025-10-19
10	110	210	\N	2025-10-10	\N	2025-10-20
\.


--
-- TOC entry 5134 (class 0 OID 16839)
-- Dependencies: 252
-- Data for Name: business_limits; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.business_limits (rule_key, threshold, active) FROM stdin;
\.


--
-- TOC entry 5122 (class 0 OID 16703)
-- Dependencies: 233
-- Data for Name: fine; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.fine (fineid, borrowid, amount, paymentdate, status) FROM stdin;
21	1	1000.00	2025-10-12	Paid
22	2	500.00	2025-10-16	Paid
23	3	1500.00	\N	Unpaid
24	4	800.00	2025-10-19	Paid
302	2	2000.00	2025-10-28	Y
\.


--
-- TOC entry 5132 (class 0 OID 16829)
-- Dependencies: 250
-- Data for Name: hier; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.hier (parent_id, child_id) FROM stdin;
BOOKS	FICTION
BOOKS	NONFICTION
FICTION	NOVEL
FICTION	SHORTSTORY
NONFICTION	BIOGRAPHY
NONFICTION	SCIENCE
SCIENCE	PHYSICS
SCIENCE	CHEMISTRY
\.


--
-- TOC entry 5116 (class 0 OID 16663)
-- Dependencies: 227
-- Data for Name: member; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.member (memberid, fullname, contact, address, email) FROM stdin;
1	Alice Johnson	0788123456	Kigali, Rwanda	alice.johnson@email.com
2	Brian Mukasa	0788234567	Nairobi, Kenya	brian.mukasa@email.com
3	Catherine Niyonsaba	0788345678	Butare, Rwanda	catherine.niyonsaba@email.com
4	David Smith	0788456789	Kigali, Rwanda	david.smith@email.com
5	Emily Uwase	0788567890	Musanze, Rwanda	emily.uwase@email.com
6	Franklin Okello	0788678901	Kampala, Uganda	franklin.okello@email.com
7	Grace Irakoze	0788789012	Gisenyi, Rwanda	grace.irakoze@email.com
8	Henry Kimani	0788890123	Nairobi, Kenya	henry.kimani@email.com
9	Isabelle Mukundi	0788901234	Kigali, Rwanda	isabelle.mukundi@email.com
10	James Mwangi	0788012345	Kigali, Rwanda	james.mwangi@email.com
\.


--
-- TOC entry 5118 (class 0 OID 16671)
-- Dependencies: 229
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.staff (staffid, fullname, role, phone, shift) FROM stdin;
1	Jean Claude Uwimana	Librarian	0788000001	Morning
2	Alice Mukamana	Assistant Librarian	0788000002	Afternoon
3	Eric Nshimiyimana	Library Technician	0788000003	Evening
4	Beatrice Umutoni	Front Desk Officer	0788000004	Morning
5	Samuel Habimana	Data Clerk	0788000005	Afternoon
6	Innocent Mugisha	Inventory Manager	0788000006	Morning
7	Grace Uwase	Book Cataloguer	0788000007	Evening
8	David Mugenzi	Security Officer	0788000008	Night
9	Claudine Niyitegeka	Cleaner	0788000009	Morning
10	Patrick Nkurunziza	IT Support	0788000010	Afternoon
\.


--
-- TOC entry 5133 (class 0 OID 16836)
-- Dependencies: 251
-- Data for Name: triple; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.triple (s, p, o) FROM stdin;
Book1	written_by	Author1
Book1	belongs_to	Fiction
Book2	written_by	Author2
Book2	belongs_to	Science
\.


--
-- TOC entry 5128 (class 0 OID 16746)
-- Dependencies: 239
-- Data for Name: clients; Type: TABLE DATA; Schema: sales; Owner: postgres
--

COPY sales.clients (client_id, first_name, last_name, email, phone, registered_date) FROM stdin;
\.


--
-- TOC entry 5124 (class 0 OID 16717)
-- Dependencies: 235
-- Data for Name: customers; Type: TABLE DATA; Schema: sales; Owner: postgres
--

COPY sales.customers (customer_id, name, email, joined_date) FROM stdin;
\.


--
-- TOC entry 5126 (class 0 OID 16731)
-- Dependencies: 237
-- Data for Name: orders; Type: TABLE DATA; Schema: sales; Owner: postgres
--

COPY sales.orders (order_id, customer_id, order_date, amount) FROM stdin;
\.


--
-- TOC entry 5152 (class 0 OID 0)
-- Dependencies: 222
-- Name: author_authorid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.author_authorid_seq', 9, true);


--
-- TOC entry 5153 (class 0 OID 0)
-- Dependencies: 224
-- Name: book_bookid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.book_bookid_seq', 10, true);


--
-- TOC entry 5154 (class 0 OID 0)
-- Dependencies: 230
-- Name: borrow_borrowid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.borrow_borrowid_seq', 104, true);


--
-- TOC entry 5155 (class 0 OID 0)
-- Dependencies: 232
-- Name: fine_fineid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.fine_fineid_seq', 24, true);


--
-- TOC entry 5156 (class 0 OID 0)
-- Dependencies: 226
-- Name: member_memberid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.member_memberid_seq', 10, true);


--
-- TOC entry 5157 (class 0 OID 0)
-- Dependencies: 228
-- Name: staff_staffid_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.staff_staffid_seq', 10, true);


--
-- TOC entry 5158 (class 0 OID 0)
-- Dependencies: 238
-- Name: clients_client_id_seq; Type: SEQUENCE SET; Schema: sales; Owner: postgres
--

SELECT pg_catalog.setval('sales.clients_client_id_seq', 1, false);


--
-- TOC entry 5159 (class 0 OID 0)
-- Dependencies: 234
-- Name: customers_customer_id_seq; Type: SEQUENCE SET; Schema: sales; Owner: postgres
--

SELECT pg_catalog.setval('sales.customers_customer_id_seq', 1, false);


--
-- TOC entry 5160 (class 0 OID 0)
-- Dependencies: 236
-- Name: orders_order_id_seq; Type: SEQUENCE SET; Schema: sales; Owner: postgres
--

SELECT pg_catalog.setval('sales.orders_order_id_seq', 1, false);


--
-- TOC entry 4933 (class 2606 OID 16648)
-- Name: author author_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.author
    ADD CONSTRAINT author_pkey PRIMARY KEY (authorid);


--
-- TOC entry 4935 (class 2606 OID 16656)
-- Name: book book_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_pkey PRIMARY KEY (bookid);


--
-- TOC entry 4941 (class 2606 OID 16685)
-- Name: borrow borrow_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrow
    ADD CONSTRAINT borrow_pkey PRIMARY KEY (borrowid);


--
-- TOC entry 4943 (class 2606 OID 16709)
-- Name: fine fine_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fine
    ADD CONSTRAINT fine_pkey PRIMARY KEY (fineid);


--
-- TOC entry 4937 (class 2606 OID 16669)
-- Name: member member_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.member
    ADD CONSTRAINT member_pkey PRIMARY KEY (memberid);


--
-- TOC entry 4955 (class 2606 OID 16835)
-- Name: hier pk_hier; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hier
    ADD CONSTRAINT pk_hier PRIMARY KEY (parent_id, child_id);


--
-- TOC entry 4939 (class 2606 OID 16677)
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (staffid);


--
-- TOC entry 4951 (class 2606 OID 16756)
-- Name: clients clients_email_key; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.clients
    ADD CONSTRAINT clients_email_key UNIQUE (email);


--
-- TOC entry 4953 (class 2606 OID 16754)
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (client_id);


--
-- TOC entry 4945 (class 2606 OID 16729)
-- Name: customers customers_email_key; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT customers_email_key UNIQUE (email);


--
-- TOC entry 4947 (class 2606 OID 16727)
-- Name: customers customers_pkey; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.customers
    ADD CONSTRAINT customers_pkey PRIMARY KEY (customer_id);


--
-- TOC entry 4949 (class 2606 OID 16738)
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (order_id);


--
-- TOC entry 4962 (class 2620 OID 16847)
-- Name: fine trg_fine_check_limit; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_fine_check_limit BEFORE INSERT OR UPDATE ON public.fine FOR EACH ROW EXECUTE FUNCTION public.trg_fine_business_limit();


--
-- TOC entry 4956 (class 2606 OID 16657)
-- Name: book book_authorid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.book
    ADD CONSTRAINT book_authorid_fkey FOREIGN KEY (authorid) REFERENCES public.author(authorid) ON DELETE CASCADE;


--
-- TOC entry 4957 (class 2606 OID 16686)
-- Name: borrow borrow_bookid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrow
    ADD CONSTRAINT borrow_bookid_fkey FOREIGN KEY (bookid) REFERENCES public.book(bookid) ON DELETE CASCADE;


--
-- TOC entry 4958 (class 2606 OID 16691)
-- Name: borrow borrow_memberid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrow
    ADD CONSTRAINT borrow_memberid_fkey FOREIGN KEY (memberid) REFERENCES public.member(memberid) ON DELETE CASCADE;


--
-- TOC entry 4959 (class 2606 OID 16696)
-- Name: borrow borrow_staffid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.borrow
    ADD CONSTRAINT borrow_staffid_fkey FOREIGN KEY (staffid) REFERENCES public.staff(staffid) ON DELETE SET NULL;


--
-- TOC entry 4960 (class 2606 OID 16710)
-- Name: fine fine_borrowid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fine
    ADD CONSTRAINT fine_borrowid_fkey FOREIGN KEY (borrowid) REFERENCES public.borrow(borrowid) ON DELETE CASCADE;


--
-- TOC entry 4961 (class 2606 OID 16739)
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: sales; Owner: postgres
--

ALTER TABLE ONLY sales.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES sales.customers(customer_id);


-- Completed on 2025-10-31 16:08:50

--
-- PostgreSQL database dump complete
--

\unrestrict mkzigh4SSYTVFvFrW6WaNXMOhaq0zgfflzwcNZ9ZaB5c6kGIh2wjRPddYjrulKj

