--
-- PostgreSQL database dump
--

\restrict E1272WzQJxFauFWJXm2RR1TogBK2jdkT7EBkvcblgiYHV1kbRYTxS51uzaEGVgG

-- Dumped from database version 16.10
-- Dumped by pg_dump version 16.10

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
-- Name: update_last_updated(); Type: FUNCTION; Schema: public; Owner: crypto_user
--

CREATE FUNCTION public.update_last_updated() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.last_updated = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_last_updated() OWNER TO crypto_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: crypto_prices; Type: TABLE; Schema: public; Owner: crypto_user
--

CREATE TABLE public.crypto_prices (
    price_id integer NOT NULL,
    coin_symbol character varying(20) NOT NULL,
    price_usd numeric(20,8) NOT NULL,
    price_eur numeric(20,8),
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    source character varying(50)
);


ALTER TABLE public.crypto_prices OWNER TO crypto_user;

--
-- Name: crypto_prices_price_id_seq; Type: SEQUENCE; Schema: public; Owner: crypto_user
--

CREATE SEQUENCE public.crypto_prices_price_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.crypto_prices_price_id_seq OWNER TO crypto_user;

--
-- Name: crypto_prices_price_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: crypto_user
--

ALTER SEQUENCE public.crypto_prices_price_id_seq OWNED BY public.crypto_prices.price_id;


--
-- Name: holdings; Type: TABLE; Schema: public; Owner: crypto_user
--

CREATE TABLE public.holdings (
    holding_id integer NOT NULL,
    wallet_id integer NOT NULL,
    coin_symbol character varying(20) NOT NULL,
    amount numeric(30,18) NOT NULL,
    network character varying(50) DEFAULT 'default'::character varying,
    last_updated timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.holdings OWNER TO crypto_user;

--
-- Name: holdings_holding_id_seq; Type: SEQUENCE; Schema: public; Owner: crypto_user
--

CREATE SEQUENCE public.holdings_holding_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.holdings_holding_id_seq OWNER TO crypto_user;

--
-- Name: holdings_holding_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: crypto_user
--

ALTER SEQUENCE public.holdings_holding_id_seq OWNED BY public.holdings.holding_id;


--
-- Name: transactions; Type: TABLE; Schema: public; Owner: crypto_user
--

CREATE TABLE public.transactions (
    transaction_id integer NOT NULL,
    wallet_id integer NOT NULL,
    coin_symbol character varying(20) NOT NULL,
    transaction_type character varying(20) NOT NULL,
    amount numeric(30,18) NOT NULL,
    price_at_time numeric(20,8),
    network character varying(50),
    transaction_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    notes text
);


ALTER TABLE public.transactions OWNER TO crypto_user;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: crypto_user
--

CREATE SEQUENCE public.transactions_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transactions_transaction_id_seq OWNER TO crypto_user;

--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: crypto_user
--

ALTER SEQUENCE public.transactions_transaction_id_seq OWNED BY public.transactions.transaction_id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: crypto_user
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    name character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_login timestamp without time zone
);


ALTER TABLE public.users OWNER TO crypto_user;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: crypto_user
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO crypto_user;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: crypto_user
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: wallets; Type: TABLE; Schema: public; Owner: crypto_user
--

CREATE TABLE public.wallets (
    wallet_id integer NOT NULL,
    user_id integer NOT NULL,
    wallet_name character varying(255) NOT NULL,
    wallet_type character varying(50) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.wallets OWNER TO crypto_user;

--
-- Name: wallets_wallet_id_seq; Type: SEQUENCE; Schema: public; Owner: crypto_user
--

CREATE SEQUENCE public.wallets_wallet_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.wallets_wallet_id_seq OWNER TO crypto_user;

--
-- Name: wallets_wallet_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: crypto_user
--

ALTER SEQUENCE public.wallets_wallet_id_seq OWNED BY public.wallets.wallet_id;


--
-- Name: crypto_prices price_id; Type: DEFAULT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.crypto_prices ALTER COLUMN price_id SET DEFAULT nextval('public.crypto_prices_price_id_seq'::regclass);


--
-- Name: holdings holding_id; Type: DEFAULT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.holdings ALTER COLUMN holding_id SET DEFAULT nextval('public.holdings_holding_id_seq'::regclass);


--
-- Name: transactions transaction_id; Type: DEFAULT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.transactions ALTER COLUMN transaction_id SET DEFAULT nextval('public.transactions_transaction_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Name: wallets wallet_id; Type: DEFAULT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.wallets ALTER COLUMN wallet_id SET DEFAULT nextval('public.wallets_wallet_id_seq'::regclass);


--
-- Data for Name: crypto_prices; Type: TABLE DATA; Schema: public; Owner: crypto_user
--

COPY public.crypto_prices (price_id, coin_symbol, price_usd, price_eur, last_updated, source) FROM stdin;
1	BTC	107352.00000000	93047.00000000	2025-11-03 06:32:58.341483	coingecko
2	ETH	3720.53000000	3224.76000000	2025-11-03 06:32:58.376228	coingecko
125	ONDO	0.64850700	0.56209300	2025-11-03 06:32:58.376703	coingecko
17	KASPA	0.04869998	0.04221061	2025-11-03 06:32:58.376335	coingecko
5	POL	0.18115800	0.15701800	2025-11-03 06:32:58.376894	coingecko
14	DOGE	0.17365600	0.15051600	2025-11-03 06:32:58.376805	coingecko
4	PAXG	4012.26000000	3477.62000000	2025-11-03 06:32:58.37708	coingecko
131	SOL	175.99000000	152.54000000	2025-11-03 06:32:58.377277	coingecko
7	USDT	1.00000000	0.86680000	2025-11-03 06:32:58.377429	coingecko
3	USDC	0.99978700	0.86656300	2025-11-03 06:32:58.377649	coingecko
\.


--
-- Data for Name: holdings; Type: TABLE DATA; Schema: public; Owner: crypto_user
--

COPY public.holdings (holding_id, wallet_id, coin_symbol, amount, network, last_updated) FROM stdin;
15	6	ETH	0.000041697954621000	default	2025-11-02 18:36:02.664383
17	6	POL	8.353989398659001000	default	2025-11-02 18:37:31.779905
18	5	BTC	0.026893770000000000	default	2025-11-02 18:38:44.430997
19	6	BTC	0.030582570000000000	default	2025-11-02 18:39:24.710244
20	5	ETH	0.851108071542066800	default	2025-11-02 18:39:53.333768
21	5	USDC	749.074293000000000000	POLYGON	2025-11-02 18:40:34.493447
22	6	USDC	12.620000000000000000	POLYGON	2025-11-02 18:41:06.085853
23	5	POL	4.875530500217530000	default	2025-11-02 18:41:46.34931
24	5	PAXG	0.150010383396821100	default	2025-11-02 18:42:09.540901
27	8	ETH	0.010429450000000000	default	2025-11-02 18:59:47.635842
28	8	USDC	25.310000000000000000	POLYGON	2025-11-02 19:00:10.050542
29	8	KASPA	212.610852840000000000	default	2025-11-02 19:00:39.394604
30	8	USDT	10.000000000000000000	TRON	2025-11-02 19:01:09.961925
31	8	SOL	0.035484640000000000	default	2025-11-02 19:01:36.773606
33	8	DOGE	30.088113180000000000	default	2025-11-02 19:02:24.64966
34	8	ARBITRUM ONE(ETH)	0.001178620000000000	default	2025-11-02 19:03:10.033415
35	8	ONDO	4.515583480000000000	default	2025-11-02 19:03:47.244037
36	8	POL	1.290981160000000000	default	2025-11-02 19:04:30.176116
37	8	PAXG	0.001460000000000000	default	2025-11-02 19:11:42.796495
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: crypto_user
--

COPY public.transactions (transaction_id, wallet_id, coin_symbol, transaction_type, amount, price_at_time, network, transaction_date, notes) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: crypto_user
--

COPY public.users (user_id, email, password_hash, name, created_at, last_login) FROM stdin;
2	bob@gmail.com	$2b$10$USp8Z3dBkjE0L5lh3ItdquvOZyh6F71fFD0pSCq9h5rcK3KbH6MCC	bob	2025-11-02 13:30:53.166497	2025-11-02 13:31:34.876264
3	ardeid@gmail.com	$2b$10$Q0UHmhH.MatHS1aTQ6CctelzkFXVmKTkL2HmBBpb7fFklveg.BQO.	ardeid	2025-11-02 14:22:25.664344	2025-11-02 19:14:21.11575
1	gilles@example.com	$2b$10$XT5rTQ/g27lvA8p4G.tn7Ohl8aPLpN.bIXyfJRq6OKCWb6ZH/ozSm	Gilles	2025-11-02 13:24:02.609325	2025-11-02 19:39:30.03962
\.


--
-- Data for Name: wallets; Type: TABLE DATA; Schema: public; Owner: crypto_user
--

COPY public.wallets (wallet_id, user_id, wallet_name, wallet_type, created_at) FROM stdin;
5	3	ARDEID-TG	TANGEM	2025-11-02 14:22:59.948807
6	3	ARDEID-BR	BRIDGE	2025-11-02 14:23:14.098352
8	1	TANGEM	TANGEM	2025-11-02 18:59:13.480251
\.


--
-- Name: crypto_prices_price_id_seq; Type: SEQUENCE SET; Schema: public; Owner: crypto_user
--

SELECT pg_catalog.setval('public.crypto_prices_price_id_seq', 1543, true);


--
-- Name: holdings_holding_id_seq; Type: SEQUENCE SET; Schema: public; Owner: crypto_user
--

SELECT pg_catalog.setval('public.holdings_holding_id_seq', 37, true);


--
-- Name: transactions_transaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: crypto_user
--

SELECT pg_catalog.setval('public.transactions_transaction_id_seq', 1, false);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: crypto_user
--

SELECT pg_catalog.setval('public.users_user_id_seq', 3, true);


--
-- Name: wallets_wallet_id_seq; Type: SEQUENCE SET; Schema: public; Owner: crypto_user
--

SELECT pg_catalog.setval('public.wallets_wallet_id_seq', 8, true);


--
-- Name: crypto_prices crypto_prices_coin_symbol_key; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.crypto_prices
    ADD CONSTRAINT crypto_prices_coin_symbol_key UNIQUE (coin_symbol);


--
-- Name: crypto_prices crypto_prices_pkey; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.crypto_prices
    ADD CONSTRAINT crypto_prices_pkey PRIMARY KEY (price_id);


--
-- Name: holdings holdings_pkey; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT holdings_pkey PRIMARY KEY (holding_id);


--
-- Name: transactions transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (transaction_id);


--
-- Name: holdings unique_coin_per_wallet; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT unique_coin_per_wallet UNIQUE (wallet_id, coin_symbol, network);


--
-- Name: wallets unique_wallet_per_user; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT unique_wallet_per_user UNIQUE (user_id, wallet_name);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: wallets wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_pkey PRIMARY KEY (wallet_id);


--
-- Name: idx_crypto_prices_symbol; Type: INDEX; Schema: public; Owner: crypto_user
--

CREATE INDEX idx_crypto_prices_symbol ON public.crypto_prices USING btree (coin_symbol);


--
-- Name: idx_holdings_coin_symbol; Type: INDEX; Schema: public; Owner: crypto_user
--

CREATE INDEX idx_holdings_coin_symbol ON public.holdings USING btree (coin_symbol);


--
-- Name: idx_holdings_wallet_id; Type: INDEX; Schema: public; Owner: crypto_user
--

CREATE INDEX idx_holdings_wallet_id ON public.holdings USING btree (wallet_id);


--
-- Name: idx_transactions_wallet_id; Type: INDEX; Schema: public; Owner: crypto_user
--

CREATE INDEX idx_transactions_wallet_id ON public.transactions USING btree (wallet_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: crypto_user
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_wallets_user_id; Type: INDEX; Schema: public; Owner: crypto_user
--

CREATE INDEX idx_wallets_user_id ON public.wallets USING btree (user_id);


--
-- Name: holdings holdings_update_timestamp; Type: TRIGGER; Schema: public; Owner: crypto_user
--

CREATE TRIGGER holdings_update_timestamp BEFORE UPDATE ON public.holdings FOR EACH ROW EXECUTE FUNCTION public.update_last_updated();


--
-- Name: crypto_prices prices_update_timestamp; Type: TRIGGER; Schema: public; Owner: crypto_user
--

CREATE TRIGGER prices_update_timestamp BEFORE UPDATE ON public.crypto_prices FOR EACH ROW EXECUTE FUNCTION public.update_last_updated();


--
-- Name: holdings holdings_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.holdings
    ADD CONSTRAINT holdings_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(wallet_id) ON DELETE CASCADE;


--
-- Name: transactions transactions_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.wallets(wallet_id) ON DELETE CASCADE;


--
-- Name: wallets wallets_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: crypto_user
--

ALTER TABLE ONLY public.wallets
    ADD CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict E1272WzQJxFauFWJXm2RR1TogBK2jdkT7EBkvcblgiYHV1kbRYTxS51uzaEGVgG

