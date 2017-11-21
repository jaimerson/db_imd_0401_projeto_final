--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.5
-- Dumped by pg_dump version 9.6.5

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgres; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


SET search_path = public, pg_catalog;

--
-- Name: add_despesas_by_file(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION add_despesas_by_file() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
	deputado RECORD;
BEGIN
    FOR deputado IN SELECT id_deputado FROM deputados d
    LOOP
        CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
        EXECUTE 'COPY temp_json FROM ' || E'\'/Users/diego/Projects/meudeputado/data/despesas/' || deputado.id_deputado::text ||
        E'.json\'';
        --|| ' CSV quote ' || E'\'\x01\'' || 'delimiter' || E'\'\x02\'';

        -- edit the <%# ... %> for the absolute path if needed

        INSERT INTO despesas (id_despesa, ano, cnpj_cpf_fornecedor, data_documento, tipo_documento,
        mes, nome_fornecedor, num_documento, num_ressarcimento, parcela, tipo_despesa, url_documento,
        valor_documento,valor_glosa,valor_liquido, id_deputado)
        SELECT (values->>'idDocumento')::int AS id_despesa,
               values->>'ano',
               values->>'cnpjCpfFornecedor',
               (values->>'dataDocumento')::date,
               values->>'tipoDocumento',
               values->>'mes',
               values->>'nomeFornecedor',
               values->>'numDocumento',
               values->>'numRessarcimento',
               (values->>'parcela')::int,
               values->>'tipoDespesa',
               values->>'urlDocumento',
               (values->>'valorDocumento')::float,
               (values->>'valorGlosa')::float,
               (values->>'valorLiquido')::float,
               deputado.id_deputado
        FROM (
          SELECT json_array_elements(values::json) AS values
          FROM temp_json
        ) elements
        WHERE (values->>'idDocumento' <> '')
        ON CONFLICT (id_despesa) DO NOTHING;

        DROP TABLE temp_json;
    END LOOP;
END;
$$;


--
-- Name: id_from_uri(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION id_from_uri(_id_deputado integer, _uri text) RETURNS TABLE(id_deputado integer, id_partido integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT _id_deputado, r::INT
  FROM substring(_uri FROM (position('partidos/' IN _uri) + 9) FOR char_length(_uri)) r;
END;
$$;


--
-- Name: testa_duracao(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION testa_duracao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Verifica valor minimo do documento
  IF ((DATE_PART('year', NEW.data_fim::date) - DATE_PART('year', NEW.data_inicio::date)) * 12 +
    (DATE_PART('month', NEW.data_fim::date) - DATE_PART('month', NEW.data_inicio::date)))  > 48 THEN
    RAISE NOTICE 'Duração de uma legislatura não pode ser maior que 4 anos.';
  END IF;

  RETURN NEW;
END;
$$;


--
-- Name: testa_valor(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION testa_valor() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Verifica valor minimo do documento
  IF NEW.valor_documento <= 0 THEN
    RAISE EXCEPTION 'Valor do documento deve ser maior que 0';
  --
  ELSEIF NEW.valor_documento > 44000 THEN
    RAISE EXCEPTION 'Valor do documento deve ser menor que 44000';
  END IF;

  RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: blocos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE blocos (
    id_bloco integer NOT NULL,
    nome character varying(100) NOT NULL
);


--
-- Name: blocos_id_bloco_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE blocos_id_bloco_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: blocos_id_bloco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE blocos_id_bloco_seq OWNED BY blocos.id_bloco;


--
-- Name: deputados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deputados (
    id_deputado integer NOT NULL,
    nome_civil character varying(255) NOT NULL,
    nome character varying(255) NOT NULL,
    cpf character varying(15) NOT NULL,
    sexo character(1),
    sigla_uf character(3),
    url_website character varying(128),
    situacao character varying(64),
    data_nascimento date,
    escolaridade character varying(64),
    id_partido character varying(10) NOT NULL,
    id_gabinete integer NOT NULL
);


--
-- Name: deputados_id_deputado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE deputados_id_deputado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: deputados_id_deputado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE deputados_id_deputado_seq OWNED BY deputados.id_deputado;


--
-- Name: deputados_proposicoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE deputados_proposicoes (
    id_proposicao integer NOT NULL,
    id_deputado integer NOT NULL
);


--
-- Name: despesas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE despesas (
    id_despesa integer NOT NULL,
    ano character varying(4) NOT NULL,
    cnpj_cpf_fornecedor character varying(100) NOT NULL,
    data_documento date NOT NULL,
    tipo_documento character varying(100) NOT NULL,
    mes character varying(3) NOT NULL,
    nome_fornecedor character varying(100) NOT NULL,
    num_documento character varying(40) NOT NULL,
    num_ressarcimento character varying(40) NOT NULL,
    parcela integer NOT NULL,
    tipo_despesa character varying(64) NOT NULL,
    url_documento character varying(64) NOT NULL,
    valor_documento double precision NOT NULL,
    valor_glosa double precision NOT NULL,
    valor_liquido double precision NOT NULL,
    id_deputado integer NOT NULL
);


--
-- Name: despesas_id_despesa_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE despesas_id_despesa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: despesas_id_despesa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE despesas_id_despesa_seq OWNED BY despesas.id_despesa;


--
-- Name: gabinetes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gabinetes (
    id_gabinete integer NOT NULL,
    nome character varying(255) NOT NULL,
    predio character varying(30),
    sala character varying(30),
    andar character varying(30),
    telefone character varying(16),
    email character varying(100)
);


--
-- Name: gabinetes_id_gabinete_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gabinetes_id_gabinete_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gabinetes_id_gabinete_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gabinetes_id_gabinete_seq OWNED BY gabinetes.id_gabinete;


--
-- Name: inscricoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE inscricoes (
    id_deputado integer NOT NULL,
    id_usuario integer NOT NULL
);


--
-- Name: legislaturas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE legislaturas (
    id_legislatura integer NOT NULL,
    data_inicio date NOT NULL,
    data_fim date NOT NULL,
    CONSTRAINT data_fim_menor CHECK ((data_fim > data_inicio)),
    CONSTRAINT data_inicio_maior CHECK ((data_inicio < data_fim))
);


--
-- Name: legislaturas_id_legislatura_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE legislaturas_id_legislatura_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: legislaturas_id_legislatura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE legislaturas_id_legislatura_seq OWNED BY legislaturas.id_legislatura;


--
-- Name: mandatos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE mandatos (
    id_deputado integer NOT NULL,
    id_legislatura integer NOT NULL
);


--
-- Name: partidos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE partidos (
    id_partido integer NOT NULL,
    nome character varying(255) NOT NULL,
    sigla character varying(10) NOT NULL
);


--
-- Name: partidos_id_partido_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE partidos_id_partido_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: partidos_id_partido_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE partidos_id_partido_seq OWNED BY partidos.id_partido;


--
-- Name: proposicoes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE proposicoes (
    id_proposicao integer NOT NULL,
    id_tipo_proposicao integer NOT NULL,
    numero integer,
    ano integer,
    ementa text,
    data_apresentacao date,
    situacao character varying(500),
    tipo_autor character varying(100),
    ementa_detalhada text,
    texto text,
    justificativa text,
    keywords character varying(500),
    CONSTRAINT year CHECK (((ano >= 1000) AND (ano <= 9999)))
);


--
-- Name: proposicoes_id_proposicao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE proposicoes_id_proposicao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: proposicoes_id_proposicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE proposicoes_id_proposicao_seq OWNED BY proposicoes.id_proposicao;


--
-- Name: tipos_proposicao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tipos_proposicao (
    id_tipo_proposicao integer NOT NULL,
    sigla character varying(20) NOT NULL,
    nome character varying(255) NOT NULL,
    descricao text
);


--
-- Name: tipos_proposicao_id_tipo_proposicao_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE tipos_proposicao_id_tipo_proposicao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_proposicao_id_tipo_proposicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE tipos_proposicao_id_tipo_proposicao_seq OWNED BY tipos_proposicao.id_tipo_proposicao;


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE usuarios (
    id_usuario integer NOT NULL,
    nome character varying(255) NOT NULL,
    data_nascimento date NOT NULL,
    email character varying(255) NOT NULL,
    password_digest text NOT NULL
);


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE usuarios_id_usuario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE usuarios_id_usuario_seq OWNED BY usuarios.id_usuario;


--
-- Name: votos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE votos (
    id_proposicao integer NOT NULL,
    id_deputado integer NOT NULL,
    voto character varying(8) NOT NULL
);


--
-- Name: vw_deputados_gastos_mensal; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW vw_deputados_gastos_mensal AS
 SELECT d.nome,
    date_part('month'::text, de.data_documento) AS month,
    d.sigla_uf,
    sum(de.valor_documento) AS sum
   FROM (despesas de
     JOIN deputados d ON ((de.id_deputado = d.id_deputado)))
  GROUP BY d.nome, (date_part('month'::text, de.data_documento)), d.sigla_uf
  ORDER BY d.nome;


--
-- Name: vw_deputados_gastos_totais; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW vw_deputados_gastos_totais AS
 SELECT d.nome,
    d.sigla_uf,
    sum(de.valor_documento) AS sum
   FROM (despesas de
     JOIN deputados d ON ((de.id_deputado = d.id_deputado)))
  GROUP BY d.nome, d.sigla_uf
  ORDER BY d.nome;


--
-- Name: vw_proposicoes_deputados; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW vw_proposicoes_deputados AS
 SELECT d.nome,
    p.ementa
   FROM ((deputados d
     JOIN deputados_proposicoes dp ON ((d.id_deputado = dp.id_deputado)))
     JOIN proposicoes p ON ((p.id_proposicao = dp.id_proposicao)))
  GROUP BY d.nome, p.ementa;


--
-- Name: vw_usuarios_deputados; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW vw_usuarios_deputados AS
 SELECT u.nome AS usuario,
    d.nome AS deputado,
    d.sigla_uf
   FROM ((inscricoes i
     JOIN deputados d ON ((d.id_deputado = i.id_deputado)))
     JOIN usuarios u ON ((u.id_usuario = i.id_usuario)));


--
-- Name: vw_votos_deputados; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW vw_votos_deputados AS
 SELECT d.nome,
    d.sigla_uf,
    v.voto,
    p.ementa
   FROM ((votos v
     JOIN deputados d ON ((d.id_deputado = v.id_deputado)))
     JOIN proposicoes p ON ((p.id_proposicao = v.id_proposicao)));


--
-- Name: blocos id_bloco; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY blocos ALTER COLUMN id_bloco SET DEFAULT nextval('blocos_id_bloco_seq'::regclass);


--
-- Name: deputados id_deputado; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY deputados ALTER COLUMN id_deputado SET DEFAULT nextval('deputados_id_deputado_seq'::regclass);


--
-- Name: despesas id_despesa; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY despesas ALTER COLUMN id_despesa SET DEFAULT nextval('despesas_id_despesa_seq'::regclass);


--
-- Name: gabinetes id_gabinete; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gabinetes ALTER COLUMN id_gabinete SET DEFAULT nextval('gabinetes_id_gabinete_seq'::regclass);


--
-- Name: legislaturas id_legislatura; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY legislaturas ALTER COLUMN id_legislatura SET DEFAULT nextval('legislaturas_id_legislatura_seq'::regclass);


--
-- Name: partidos id_partido; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY partidos ALTER COLUMN id_partido SET DEFAULT nextval('partidos_id_partido_seq'::regclass);


--
-- Name: proposicoes id_proposicao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY proposicoes ALTER COLUMN id_proposicao SET DEFAULT nextval('proposicoes_id_proposicao_seq'::regclass);


--
-- Name: tipos_proposicao id_tipo_proposicao; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipos_proposicao ALTER COLUMN id_tipo_proposicao SET DEFAULT nextval('tipos_proposicao_id_tipo_proposicao_seq'::regclass);


--
-- Name: usuarios id_usuario; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY usuarios ALTER COLUMN id_usuario SET DEFAULT nextval('usuarios_id_usuario_seq'::regclass);


--
-- Data for Name: blocos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO blocos VALUES (571, 'PP, AVANTE');
INSERT INTO blocos VALUES (570, 'PTB, PROS, PSL, PRP');


--
-- Name: blocos_id_bloco_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('blocos_id_bloco_seq', 1, false);


--
-- Data for Name: deputados; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO deputados VALUES (178950, 'ANTONIO JACOME DE LIMA JUNIOR', 'ANTÔNIO JÁCOME', '', 'M', 'RN ', NULL, 'Exercício', '1962-05-26', 'Mestrado', 'PODE', 178950);
INSERT INTO deputados VALUES (178948, 'CARLOS ALBERTO DE SOUSA ROSADO SEGUNDO', 'BETO ROSADO', '', 'M', 'RN ', NULL, 'Exercício', '1982-02-01', 'Pós-Graduação', 'PP', 178948);
INSERT INTO deputados VALUES (141428, 'FÁBIO SALUSTINO MESQUITA DE FARIA', 'FÁBIO FARIA', '', 'M', 'RN ', NULL, 'Exercício', '1977-09-01', NULL, 'PSD', 141428);
INSERT INTO deputados VALUES (141429, 'FELIPE CATALÃO MAIA', 'FELIPE MAIA', '', 'M', 'RN ', NULL, 'Exercício', '1973-12-07', NULL, 'DEM', 141429);
INSERT INTO deputados VALUES (178951, 'RAFAEL HUETE DA MOTTA', 'RAFAEL MOTTA', '', 'M', 'RN ', NULL, 'Exercício', '1986-08-15', 'Superior', 'PSB', 178951);
INSERT INTO deputados VALUES (141535, 'ROGÉRIO SIMONETTI MARINHO', 'ROGÉRIO MARINHO', '', 'M', 'RN ', NULL, 'Exercício', '1963-11-26', NULL, 'PSDB', 141535);
INSERT INTO deputados VALUES (178952, 'WALTER PEREIRA ALVES', 'WALTER ALVES', '', 'M', 'RN ', NULL, 'Exercício', '1980-02-27', 'Mestrado Incompleto', 'PMDB', 178952);
INSERT INTO deputados VALUES (178949, 'ZENAIDE MAIA CALADO PEREIRA DOS SANTOS', 'ZENAIDE MAIA', '', 'F', 'RN ', NULL, 'Exercício', '1954-11-27', 'Superior', 'PR', 178949);


--
-- Name: deputados_id_deputado_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('deputados_id_deputado_seq', 1, false);


--
-- Data for Name: deputados_proposicoes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: despesas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO despesas VALUES (5626951, '2015', '02637432411', '2015-02-01', 'Recibos/Outros', '2', 'EDICLEYTON JACOME DE OLIVEIRA', '01', '4959', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 4000, 0, 4000, 178950);
INSERT INTO despesas VALUES (5723549, '2015', '02637432411', '2015-05-03', 'Recibos/Outros', '5', 'EDICLEYTON JACOME DE OLIVEIRA', '04', '5074', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 4000, 0, 4000, 178950);
INSERT INTO despesas VALUES (5672328, '2015', '02637432411', '2015-03-03', 'Recibos/Outros', '3', 'EDICLEYTON JACOME DE OLIVEIRA', '2', '5023', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 4000, 0, 4000, 178950);
INSERT INTO despesas VALUES (5672337, '2015', '02637432411', '2015-04-03', 'Recibos/Outros', '4', 'EDICLEYTON JACOME DE OLIVEIRA', '3', '5023', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 4000, 0, 4000, 178950);
INSERT INTO despesas VALUES (5771075, '2015', '19267766000165', '2015-08-24', 'Nota Fiscal', '8', 'FSounds Soluções em Áudio', '000328872', '5153', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 900, 0, 900, 178950);
INSERT INTO despesas VALUES (5657115, '2015', '09240519000111', '2015-04-14', 'Nota Fiscal', '4', 'TARGETWARE INFORMÁTICA LTDA', '8637', '5005', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1289, 0, 1289, 178950);
INSERT INTO despesas VALUES (5635201, '2015', '08505901000147', '2015-03-23', 'Nota Fiscal', '3', 'A N DE OLIVEIRA COMBUSTIVEIS ME', '570', '4971', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3518.09999999999991, 0, 3518.09999999999991, 178950);
INSERT INTO despesas VALUES (5757501, '2015', '08202116000115', '2015-08-06', 'Nota Fiscal', '8', 'Auto Posto Aeroporto Ltda', '506350', '5118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5637886, '2015', '08202116000115', '2015-03-20', 'Nota Fiscal', '3', 'AUTO POSTO AEROPORTO LTDA', '54253', '4973', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 2.89999999999999991, 47.1000000000000014, 178950);
INSERT INTO despesas VALUES (5840204, '2015', '08202116000115', '2015-11-09', 'Nota Fiscal', '11', 'AUTO POSTO AEROPORTO LTDA', '56236', '5219', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5622057, '2015', '03494343000148', '2015-03-05', 'Nota Fiscal', '3', 'AUTO POSTO AEROPORTO LTDA.', '54103', '4953', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5816503, '2015', '08202116000115', '2015-10-13', 'Recibos/Outros', '10', 'AUTO POSTO AEROPORTO LTDA.', '561651', '5190', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 178950);
INSERT INTO despesas VALUES (5828804, '2015', '00746278000102', '2015-10-23', 'Nota Fiscal', '10', 'AUTO POSTO CHAVES LTDA', '117983', '5213', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5711118, '2015', '00746278000102', '2015-06-10', 'Nota Fiscal', '6', 'AUTO POSTO CHAVES LTDA', '46961', '5061', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 121.519999999999996, 0, 121.519999999999996, 178950);
INSERT INTO despesas VALUES (5730446, '2015', '00692418000107', '2015-07-06', 'Nota Fiscal', '7', 'AUTO POSTO CINCO ESTRELAS LTDA', '142277', '5086', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5749626, '2015', '00692418000107', '2015-07-16', 'Nota Fiscal', '7', 'AUTO POSTO CINCO ESTRELAS LTDA', '145051', '5109', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5749634, '2015', '00692418000107', '2015-08-03', 'Nota Fiscal', '8', 'AUTO POSTO CINCO ESTRELAS LTDA', '149975', '5109', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5835384, '2015', '00692418000107', '2015-10-28', 'Nota Fiscal', '10', 'AUTO POSTO CINCO ESTRELAS LTDA', '175784', '5213', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 178950);
INSERT INTO despesas VALUES (5843066, '2015', '00692418000107', '2015-11-09', 'Nota Fiscal', '11', 'AUTO POSTO CINCO ESTRELAS LTDA', '179403', '5223', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5869575, '2015', '00692418000107', '2015-12-02', 'Nota Fiscal', '12', 'AUTO POSTO CINCO ESTRELAS LTDA', '186892', '5254', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5876235, '2015', '00692418000107', '2015-12-10', 'Nota Fiscal', '12', 'AUTO POSTO CINCO ESTRELAS LTDA', '302897', '5276', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5851935, '2015', '37063328000914', '2015-11-19', 'Recibos/Outros', '11', 'AUTO POSTO DERIVADOS DE PETROLEO LTDA', '512393', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5749897, '2015', '02731610000271', '2015-08-04', 'Nota Fiscal', '8', 'AUTO POSTO ITICAR LTDA', '409633', '5109', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5769836, '2015', '02731610000271', '2015-08-20', 'Nota Fiscal', '8', 'AUTO POSTO ITICAR LTDA', '413226', '5130', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5808938, '2015', '02731610000271', '2015-10-01', 'Nota Fiscal', '10', 'AUTO POSTO ITICAR LTDA', '423512', '5180', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5835411, '2015', '02731610000271', '2015-10-29', 'Nota Fiscal', '10', 'AUTO POSTO ITICAR LTDA', '430443', '5213', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 178950);
INSERT INTO despesas VALUES (5861660, '2015', '02731610000271', '2015-12-01', 'Nota Fiscal', '12', 'AUTO POSTO ITICAR LTDA', '438426', '5249', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 178950);
INSERT INTO despesas VALUES (5869572, '2015', '02731610000271', '2015-12-08', 'Nota Fiscal', '12', 'AUTO POSTO ITICAR LTDA', '440342', '5254', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5628215, '2015', '02731610000271', '2015-03-12', 'Nota Fiscal', '3', 'AUTO POSTO ITICAR LTDA', '84435', '4966', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5664588, '2015', '02731610000271', '2015-04-19', 'Nota Fiscal', '4', 'AUTO POSTO ITICAR LTDA', '84478', '5040', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 40, 0, 40, 178950);
INSERT INTO despesas VALUES (5711189, '2015', '02731610000271', '2015-06-16', 'Nota Fiscal', '6', 'AUTO POSTO ITICAR LTDA', '84559', '5074', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5649565, '2015', '06066360000172', '2015-04-05', 'Nota Fiscal', '4', 'AUTO POSTO JARDIM BELVEDERE LTDA.', '024136', '4995', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 230, 0, 230, 178950);
INSERT INTO despesas VALUES (5631752, '2015', '10765690000204', '2015-02-04', 'Nota Fiscal', '2', 'Auto Posto Portal de Santana Ltda.', '310954', '4966', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60.6199999999999974, 0, 60.6199999999999974, 178950);
INSERT INTO despesas VALUES (5843058, '2015', '04764511000130', '2015-11-06', 'Recibos/Outros', '11', 'AUTO POSTO SONHO MEU', '010181', '5223', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 95.0400000000000063, 0, 95.0400000000000063, 178950);
INSERT INTO despesas VALUES (5620078, '2015', '00647440000135', '2015-03-04', 'Nota Fiscal', '3', 'Auto Shopping QL 06 - Com. de Der. de Petroleo LTDA', '92334', '4953', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 80, 0, 80, 178950);
INSERT INTO despesas VALUES (5847255, '2015', '00647440000135', '2015-11-16', 'Nota Fiscal', '11', 'AUTO SHOPPING QL 06 COM. DE PETRÓLEO LTDA', '629428', '5233', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5861652, '2015', '38053450000115', '2015-11-25', 'Nota Fiscal', '11', 'BR 070 COMÉRCIO DE DERIVADOS DE PETRÓLEO LTDA', '323057', '5250', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5805132, '2015', '12404136000146', '2015-09-26', 'Nota Fiscal', '9', 'BRADISEL DERIVADOS DE PETROLEO LTDA', '006114', '5173', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 250, 0, 250, 178950);
INSERT INTO despesas VALUES (5611061, '2015', '00097626000400', '2015-02-24', 'Nota Fiscal', '2', 'BRASAL COMBUSTíVEIS LTDA', '140656', '4936', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5656929, '2015', '00097626000400', '2015-04-14', 'Nota Fiscal', '4', 'BRASAL COMBUSTíVEIS LTDA', '140964', '5005', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5682583, '2015', '00097626000400', '2015-05-13', 'Nota Fiscal', '5', 'BRASAL COMBUSTíVEIS LTDA', '141189', '5038', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5702581, '2015', '00097626000400', '2015-06-07', 'Nota Fiscal', '6', 'BRASAL COMBUSTíVEIS LTDA', '141321', '5053', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 178950);
INSERT INTO despesas VALUES (5702582, '2015', '00097626000400', '2015-06-08', 'Nota Fiscal', '6', 'BRASAL COMBUSTíVEIS LTDA', '141361', '5053', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5872860, '2015', '00097626000400', '2015-12-10', 'Nota Fiscal', '12', 'BRASAL COMBUSTIVEIS LTDA', '408421', '5261', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 178950);
INSERT INTO despesas VALUES (5757497, '2015', '00097626000400', '2015-08-06', 'Nota Fiscal', '8', 'BRASAL COMBUSTíVEIS LTDA', '600634', '5118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5774138, '2015', '00097626000400', '2015-08-27', 'Nota Fiscal', '8', 'BRASAL COMBUSTíVEIS LTDA', '606178', '5134', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 80, 0, 80, 178950);
INSERT INTO despesas VALUES (5818558, '2015', '00097626000400', '2015-10-14', 'Nota Fiscal', '10', 'BRASAL COMBUSTíVEIS LTDA', '618427', '5192', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5699243, '2015', '00306597007290', '2015-06-01', 'Nota Fiscal', '6', 'cascol combustíveis ltda', '19543', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5715374, '2015', '00306597007290', '2015-06-18', 'Nota Fiscal', '6', 'Cascol Combustíveis Para Veículos  Ltda', '19721', '5066', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5728756, '2015', '00306597007290', '2015-07-01', 'Nota Fiscal', '7', 'Cascol Combustíveis Para Veículos  Ltda', '19898', '5085', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5736941, '2015', '00306597007290', '2015-07-14', 'Nota Fiscal', '7', 'Cascol Combustíveis Para Veículos  Ltda', '20002', '5096', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5600853, '2015', '00306597001179', '2015-02-04', 'Nota Fiscal', '2', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '79594', '4916', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 178950);
INSERT INTO despesas VALUES (5667396, '2015', '00306597002574', '2015-04-28', 'Nota Fiscal', '4', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA', '16929', '5010', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5600879, '2015', '00306597002655', '2015-02-03', 'Nota Fiscal', '2', 'Cascol Combustíveis para Veículos Ltda', '002374', '4916', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 65, 0, 65, 178950);
INSERT INTO despesas VALUES (5861679, '2015', '00306597002655', '2015-11-28', 'Nota Fiscal', '11', 'Cascol Combustíveis para Veículos Ltda', '3899', '5250', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 0, 178950);
INSERT INTO despesas VALUES (5690922, '2015', '00306597003112', '2015-05-20', 'Recibos/Outros', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '033657', '5040', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5728742, '2015', '00306597003112', '2015-07-05', 'Recibos/Outros', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '035878', '5085', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5765073, '2015', '00306597003112', '2015-08-18', 'Nota Fiscal', '8', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '038015', '5124', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5777654, '2015', '00306597003112', '2015-09-01', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '038710', '5137', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5784549, '2015', '00306597003112', '2015-09-04', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '038879', '5147', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5787685, '2015', '00306597003112', '2015-09-09', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '039075', '5148', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5787684, '2015', '00306597003112', '2015-09-10', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '039088', '5148', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5797580, '2015', '00306597003112', '2015-09-21', 'Recibos/Outros', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '039583', '5167', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178950);
INSERT INTO despesas VALUES (5810799, '2015', '00306597003112', '2015-10-06', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '040228', '5181', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5814473, '2015', '00306597003112', '2015-10-07', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '040303', '5187', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5816640, '2015', '00306597003112', '2015-10-13', 'Recibos/Outros', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '040533', '5190', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5822017, '2015', '00306597003112', '2015-10-15', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '040672', '5201', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5825699, '2015', '00306597003112', '2015-10-20', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '040856', '5202', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5828750, '2015', '00306597003112', '2015-10-21', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '040898', '5213', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178950);
INSERT INTO despesas VALUES (5828796, '2015', '00306597003112', '2015-10-25', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '041049', '5213', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5847635, '2015', '00306597003112', '2015-11-16', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '042057', '5233', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 20, 0, 20, 178950);
INSERT INTO despesas VALUES (5851933, '2015', '00306597003112', '2015-11-18', 'Recibos/Outros', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '042144', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5863461, '2015', '00306597003112', '2015-12-02', 'Nota Fiscal', '12', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '042648', '5247', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5876052, '2015', '00306597003112', '2015-12-15', 'Nota Fiscal', '12', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '043184', '5276', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5632931, '2015', '00306597003112', '2015-03-18', 'Nota Fiscal', '3', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '15680', '4966', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 65, 0, 65, 178950);
INSERT INTO despesas VALUES (5664602, '2015', '00306597003112', '2015-04-27', 'Nota Fiscal', '4', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '16299', '5010', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5631726, '2015', '00306597003112', '2015-03-16', 'Nota Fiscal', '3', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '16892', '4966', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5711123, '2015', '00306597003112', '2015-06-09', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17201', '5061', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5706587, '2015', '00306597003112', '2015-06-10', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17206', '5059', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 120.879999999999995, 0, 120.879999999999995, 178950);
INSERT INTO despesas VALUES (5711114, '2015', '00306597003112', '2015-06-10', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17218', '5061', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5702577, '2015', '00306597003112', '2015-06-06', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17259', '5053', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5702572, '2015', '00306597003112', '2015-06-07', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17268', '5053', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5702574, '2015', '00306597003112', '2015-06-06', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17283', '5053', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5698385, '2015', '00306597003112', '2015-05-28', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17301', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 80, 0, 80, 178950);
INSERT INTO despesas VALUES (5693475, '2015', '00306597003112', '2015-05-26', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17380', '5043', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5688209, '2015', '00306597003112', '2015-05-19', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17424', '5040', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5681123, '2015', '00306597003112', '2015-05-05', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17479', '5035', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 90, 0, 90, 178950);
INSERT INTO despesas VALUES (5681132, '2015', '00306597003112', '2015-05-08', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17496', '5035', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 178950);
INSERT INTO despesas VALUES (5728752, '2015', '00306597003112', '2015-07-03', 'Nota Fiscal', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17580', '5085', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5793310, '2015', '00306597003112', '2015-09-16', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17855', '5153', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5784495, '2015', '00306597003112', '2015-09-03', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '18021', '5147', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5757528, '2015', '00306597003112', '2015-08-11', 'Nota Fiscal', '8', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '18272', '5118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178950);
INSERT INTO despesas VALUES (5702575, '2015', '00306597003112', '2015-06-03', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '19556', '5053', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5656892, '2015', '00306597004518', '2015-04-08', 'Nota Fiscal', '4', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17333', '5005', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178950);
INSERT INTO despesas VALUES (5828812, '2015', '00306597006219', '2015-10-24', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '034741', '5213', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5644643, '2015', '00306597007290', '2015-04-01', 'Nota Fiscal', '4', 'Cascol Combustíveis para Veículos LTDA', '18692', '4982', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178950);
INSERT INTO despesas VALUES (5672098, '2015', '00306597003627', '2015-04-30', 'Nota Fiscal', '4', 'CASCOL COMBUSTIVEL', '47388', '5021', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 40, 0, 40, 178950);
INSERT INTO despesas VALUES (5749672, '2015', '69943686000150', '2015-07-26', 'Nota Fiscal', '7', 'CEMOPEL CM PETROLEO LTDA', '284125', '5109', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178950);
INSERT INTO despesas VALUES (5659841, '2015', '00540252000103', '2015-04-17', 'Nota Fiscal', '4', 'PAPELARIA ABC Com. e Ind. LTDA', '44853', '5006', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 333.800000000000011, 0, 333.800000000000011, 178948);
INSERT INTO despesas VALUES (5820545, '2015', '35649219000796', '2015-08-08', 'Nota Fiscal', '8', 'ALTO POSTO PASSA E FICA', '095096', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100.019999999999996, 0, 100.019999999999996, 178948);
INSERT INTO despesas VALUES (5664586, '2015', '35649219000796', '2015-04-22', 'Nota Fiscal', '4', 'ALTO POSTO PASSA E FICA', '190201', '5010', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 127.030000000000001, 0, 127.030000000000001, 178948);
INSERT INTO despesas VALUES (5709085, '2015', '35649219000796', '2015-06-01', 'Nota Fiscal', '6', 'ALTO POSTO PASSA E FICA', '219490', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 68.0400000000000063, 0, 68.0400000000000063, 178948);
INSERT INTO despesas VALUES (5684576, '2015', '35649219000796', '2015-05-08', 'Nota Fiscal', '5', 'ALTO POSTO PASSA E FICA', '457981', '5037', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 145.009999999999991, 0, 145.009999999999991, 178948);
INSERT INTO despesas VALUES (5820539, '2015', '08202116000115', '2015-08-05', 'Nota Fiscal', '8', 'AUTO POSTO AEROPORTO LTDA.', '505558', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5820557, '2015', '08202116000115', '2015-08-17', 'Nota Fiscal', '8', 'AUTO POSTO AEROPORTO LTDA.', '513050', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5708789, '2015', '37063328001309', '2015-05-27', 'Nota Fiscal', '5', 'Auto Shopping Derivados de Petroleo Ltda', '048349', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 106.840000000000003, 0, 106.840000000000003, 178948);
INSERT INTO despesas VALUES (5630292, '2015', '37128428000124', '2015-03-17', 'Nota Fiscal', '3', 'AUTO SHOPPING SOBRADINHO DER. DE PETROLEO LTDA', '218666', '4970', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 40, 0, 40, 178948);
INSERT INTO despesas VALUES (5820550, '2015', '00306597003112', '2015-07-17', 'Nota Fiscal', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '036486', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5854924, '2015', '00306597003112', '2015-11-05', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '041533', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178948);
INSERT INTO despesas VALUES (5854940, '2015', '00306597003112', '2015-11-10', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '19204', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 130, 0, 130, 178948);
INSERT INTO despesas VALUES (5637532, '2015', '00306597005328', '2015-03-18', 'Nota Fiscal', '3', 'Cascol Combustíveis para Veículos LTDA', '002940', '4973', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 178948);
INSERT INTO despesas VALUES (5637529, '2015', '00306597005328', '2015-03-18', 'Nota Fiscal', '3', 'Cascol Combustíveis para Veículos LTDA', '003073', '4973', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178948);
INSERT INTO despesas VALUES (5820553, '2015', '00306597006995', '2015-08-25', 'Nota Fiscal', '8', 'Cascol Combustiveis Para Veiculos Ltda', '063971', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 149.150000000000006, 0, 149.150000000000006, 178948);
INSERT INTO despesas VALUES (5663746, '2015', '00306597006308', '2015-04-15', 'Nota Fiscal', '4', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '019628', '5010', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5630299, '2015', '07821726000134', '2015-03-13', 'Nota Fiscal', '3', 'DFM - Derivados de Petróleo Ltda', '39904', '4970', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 178948);
INSERT INTO despesas VALUES (5621946, '2015', '02343493000198', '2015-03-07', 'Nota Fiscal', '3', 'DISTRIBUIDORA DE COMBUSTIVEIS FRONT LTDA.', '458190', '4950', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60.009999999999998, 0, 60.009999999999998, 178948);
INSERT INTO despesas VALUES (5663749, '2015', '19257042000130', '2015-04-19', 'Nota Fiscal', '4', 'DRA 4 Derivados de Petróleo LTDA', '2721', '5010', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5664290, '2015', '19257042000130', '2015-04-27', 'Nota Fiscal', '4', 'DRA 4 Derivados de Petróleo LTDA', '2866', '5010', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 135.159999999999997, 0, 135.159999999999997, 178948);
INSERT INTO despesas VALUES (5676859, '2015', '19257042000130', '2015-05-05', 'Recibos/Outros', '5', 'DRA 4 Derivados de Petróleo LTDA', '3036', '5025', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 40, 0, 40, 178948);
INSERT INTO despesas VALUES (5682360, '2015', '19257042000130', '2015-05-12', 'Nota Fiscal', '5', 'DRA 4 Derivados de Petróleo LTDA', '3191', '5035', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5820530, '2015', '19257042000130', '2015-08-12', 'Nota Fiscal', '8', 'DRA4 DERIVADOS DE PETROLEO LTDA', '5095', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5820529, '2015', '19257042000130', '2015-08-20', 'Nota Fiscal', '8', 'DRA4 DERIVADOS DE PETROLEO LTDA', '5250', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5820528, '2015', '19257042000130', '2015-08-30', 'Nota Fiscal', '8', 'DRA4 DERIVADOS DE PETROLEO LTDA', '5443', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 178948);
INSERT INTO despesas VALUES (5820535, '2015', '19257042000130', '2015-09-12', 'Nota Fiscal', '9', 'DRA4 DERIVADOS DE PETROLEO LTDA', '5711', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 123.040000000000006, 0, 123.040000000000006, 178948);
INSERT INTO despesas VALUES (5815074, '2015', '19257042000130', '2015-09-15', 'Nota Fiscal', '9', 'DRA4 DERIVADOS DE PETROLEO LTDA', '5785', '5183', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5815076, '2015', '19257042000130', '2015-09-24', 'Nota Fiscal', '9', 'DRA4 DERIVADOS DE PETROLEO LTDA', '6011', '5183', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5815080, '2015', '19257042000130', '2015-09-30', 'Nota Fiscal', '9', 'DRA4 DERIVADOS DE PETROLEO LTDA', '6136', '5183', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5820533, '2015', '19257042000130', '2015-10-07', 'Recibos/Outros', '10', 'DRA4 DERIVADOS DE PETROLEO LTDA', '6925', '5196', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5854900, '2015', '19257042000130', '2015-11-17', 'Recibos/Outros', '11', 'DRA4 DERIVADOS DE PETROLEO LTDA', '7180', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5866608, '2015', '19257042000130', '2015-11-26', 'Nota Fiscal', '11', 'DRA4 DERIVADOS DE PETROLEO LTDA', '7382', '5252', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5858318, '2015', '14378801000523', '2015-10-17', 'Nota Fiscal', '10', 'JMI COMERCIO DERIVADOS DE PETRÓLEO LTDA', '000959', '5245', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 129.900000000000006, 0, 129.900000000000006, 178948);
INSERT INTO despesas VALUES (5656208, '2015', '35298330000513', '2015-04-14', 'Nota Fiscal', '4', 'JVC COMERCIAL LTDA', '310385', '5001', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5709444, '2015', '35298330000602', '2015-05-29', 'Nota Fiscal', '5', 'JVC COMERCIAL LTDA', '134858', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 122.280000000000001, 0, 122.280000000000001, 178948);
INSERT INTO despesas VALUES (5664569, '2015', '08383051000151', '2015-04-18', 'Nota Fiscal', '4', 'MELO E FILHOS LTDA', '021960', '5010', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 132, 0, 132, 178948);
INSERT INTO despesas VALUES (5858322, '2015', '06928122000129', '2015-11-09', 'Nota Fiscal', '11', 'NOVO HORIZONTE COM. E DERIV. DE PETROLEO LTDA', '463628', '5245', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 161.569999999999993, 0, 161.569999999999993, 178948);
INSERT INTO despesas VALUES (5621948, '2015', '24206617001289', '2015-02-25', 'Nota Fiscal', '2', 'PARELHAS GAS LTDA', '321317', '4950', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5708792, '2015', '19257042000130', '2015-05-17', 'Nota Fiscal', '5', 'POSTO 403', '3290', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 178948);
INSERT INTO despesas VALUES (5709446, '2015', '19257042000130', '2015-05-20', 'Nota Fiscal', '5', 'POSTO 403', '3364', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 138.990000000000009, 0, 138.990000000000009, 178948);
INSERT INTO despesas VALUES (5709088, '2015', '19257042000130', '2015-06-02', 'Nota Fiscal', '6', 'POSTO 403', '3661', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 134.680000000000007, 0, 134.680000000000007, 178948);
INSERT INTO despesas VALUES (5709089, '2015', '19257042000130', '2015-06-10', 'Nota Fiscal', '6', 'POSTO 403', '3819', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5709441, '2015', '19257042000130', '2015-06-12', 'Nota Fiscal', '6', 'POSTO 403', '3866', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5656195, '2015', '08202116000115', '2015-04-14', 'Nota Fiscal', '4', 'Posto Aeroporto', '54405', '5001', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 140, 0, 140, 178948);
INSERT INTO despesas VALUES (5596666, '2015', '10750039000180', '2015-02-02', 'Nota Fiscal', '2', 'POSTO DISBRAVE IMPERIAL LTDA', '268582', '4904', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 121.150000000000006, 0, 121.150000000000006, 178948);
INSERT INTO despesas VALUES (5600371, '2015', '10750039000180', '2015-02-06', 'Nota Fiscal', '2', 'POSTO DISBRAVE IMPERIAL LTDA', '271343', '4913', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5614963, '2015', '10750039000180', '2015-03-02', 'Nota Fiscal', '3', 'POSTO DISBRAVE IMPERIAL LTDA', '282809', '4946', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 141.810000000000002, 0, 141.810000000000002, 178948);
INSERT INTO despesas VALUES (5625113, '2015', '10750039000180', '2015-03-11', 'Nota Fiscal', '3', 'POSTO DISBRAVE IMPERIAL LTDA', '287687', '4955', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5614554, '2015', '10750039000180', '2015-02-24', 'Nota Fiscal', '2', 'POSTO DISBRAVE IMPERIAL LTDA', '292973', '4946', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5637527, '2015', '10750039000180', '2015-03-19', 'Nota Fiscal', '3', 'POSTO DISBRAVE IMPERIAL LTDA', '302269', '4973', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178948);
INSERT INTO despesas VALUES (5652025, '2015', '10750039000180', '2015-04-07', 'Nota Fiscal', '4', 'POSTO DISBRAVE IMPERIAL LTDA', '309368', '4996', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 120.019999999999996, 0, 120.019999999999996, 178948);
INSERT INTO despesas VALUES (5676816, '2015', '10750039000180', '2015-05-06', 'Recibos/Outros', '5', 'POSTO DISBRAVE IMPERIAL LTDA', '316659', '5025', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 142.710000000000008, 0, 142.710000000000008, 178948);
INSERT INTO despesas VALUES (5711334, '2015', '10750039000180', '2015-06-08', 'Nota Fiscal', '6', 'POSTO DISBRAVE IMPERIAL LTDA', '334787', '5061', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 178948);
INSERT INTO despesas VALUES (5854849, '2015', '10750039000180', '2015-10-27', 'Nota Fiscal', '10', 'POSTO DISBRAVE IMPERIAL LTDA', '416627', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 140, 0, 140, 178948);
INSERT INTO despesas VALUES (5854914, '2015', '10750039000180', '2015-11-05', 'Nota Fiscal', '11', 'POSTO DISBRAVE IMPERIAL LTDA', '421751', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178948);
INSERT INTO despesas VALUES (5858328, '2015', '03979385000179', '2015-11-07', 'Nota Fiscal', '11', 'POSTO EMAUS COMERCIO E SERVIÇOS LTDA', '310339', '5245', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 128.360000000000014, 0, 128.360000000000014, 178948);
INSERT INTO despesas VALUES (5637555, '2015', '03979385000179', '2015-03-21', 'Nota Fiscal', '3', 'POSTO EMAUS COMERCIO E SERVIÇOS LTDA', '504998', '4973', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178948);
INSERT INTO despesas VALUES (5709437, '2015', '08350555000841', '2015-05-31', 'Nota Fiscal', '5', 'POSTO ENTRONCAMENTO', '188321', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 136.050000000000011, 0, 136.050000000000011, 178948);
INSERT INTO despesas VALUES (5619053, '2015', '12997664000156', '2015-02-26', 'Nota Fiscal', '2', 'POSTO LASER LTDA', '3214', '4946', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3918.90999999999985, 0, 3918.90999999999985, 178948);
INSERT INTO despesas VALUES (5643540, '2015', '12997664000156', '2015-03-27', 'Nota Fiscal', '3', 'POSTO LASER LTDA', '3335', '4979', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3620.01999999999998, 0, 3620.01999999999998, 178948);
INSERT INTO despesas VALUES (5670952, '2015', '12997664000156', '2015-04-28', 'Nota Fiscal', '4', 'POSTO LASER LTDA', '3442', '5022', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3728.5300000000002, 0, 3728.5300000000002, 178948);
INSERT INTO despesas VALUES (5708770, '2015', '12997664000156', '2015-05-29', 'Nota Fiscal', '5', 'POSTO LASER LTDA', '3580', '5060', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3570.34999999999991, 0, 3570.34999999999991, 178948);
INSERT INTO despesas VALUES (5729085, '2015', '12997664000156', '2015-06-29', 'Nota Fiscal', '6', 'POSTO LASER LTDA', '3757', '5086', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3629.5, 0, 3629.5, 178948);
INSERT INTO despesas VALUES (5749981, '2015', '12997664000156', '2015-07-24', 'Nota Fiscal', '7', 'POSTO LASER LTDA', '3920', '5110', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3764.15000000000009, 0, 3764.15000000000009, 178948);
INSERT INTO despesas VALUES (5783069, '2015', '12997664000156', '2015-08-26', 'Nota Fiscal', '8', 'POSTO LASER LTDA', '4040', '5147', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3122.05999999999995, 0, 3122.05999999999995, 178948);
INSERT INTO despesas VALUES (5815053, '2015', '12997664000156', '2015-09-28', 'Nota Fiscal', '9', 'POSTO LASER LTDA', '4153', '5183', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3708.13000000000011, 0, 3708.13000000000011, 178948);
INSERT INTO despesas VALUES (5834326, '2015', '12997664000156', '2015-10-27', 'Nota Fiscal', '10', 'POSTO LASER LTDA', '4282', '5218', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3830.40999999999985, 0, 3830.40999999999985, 178948);
INSERT INTO despesas VALUES (5866610, '2015', '12997664000156', '2015-11-25', 'Nota Fiscal', '11', 'POSTO LASER LTDA', '4386', '5252', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3350.75, 0, 3350.75, 178948);
INSERT INTO despesas VALUES (5886511, '2015', '12997664000156', '2015-12-22', 'Nota Fiscal', '12', 'POSTO LASER LTDA', '4496', '5294', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3621.7800000000002, 0, 3621.7800000000002, 178948);
INSERT INTO despesas VALUES (5621953, '2015', '08277717000359', '2015-03-08', 'Nota Fiscal', '3', 'POSTO PINHEIRO BORGES LTDA', '401005', '4950', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178948);
INSERT INTO despesas VALUES (5804988, '2015', '16624376000107', '2015-09-14', 'Nota Fiscal', '9', 'A & F COMUNICAÇÃO INTEGRADA LTDA ME', '59', '5185', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 5000, 0, 5000, 178948);
INSERT INTO despesas VALUES (5810566, '2015', '10902238000166', '2015-10-06', 'Nota Fiscal', '10', 'ASSOCIAÇÃO NACIONAL DA GESTÃO PÚBLICA - ANGESP', '0000000367', '5185', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 11000, 0, 11000, 178948);
INSERT INTO despesas VALUES (5820506, '2015', '17622621000100', '2015-09-24', 'Nota Fiscal', '9', 'D. R EMPRESARIAL LTDA - ME', '00000002', '5194', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 318, 0, 318, 178948);
INSERT INTO despesas VALUES (5858369, '2015', '17622621000100', '2015-10-23', 'Nota Fiscal', '10', 'D. R EMPRESARIAL LTDA - ME', '00000026', '5245', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 159, 0, 159, 178948);
INSERT INTO despesas VALUES (5858380, '2015', '17622621000100', '2015-11-12', 'Nota Fiscal', '11', 'D. R EMPRESARIAL LTDA - ME', '00000033', '5245', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 159, 0, 159, 178948);
INSERT INTO despesas VALUES (5924861, '2015', '17622621000100', '2015-12-17', 'Nota Fiscal', '12', 'D. R EMPRESARIAL LTDA - ME', '042', '5362', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 159, 0, 159, 178948);
INSERT INTO despesas VALUES (5745019, '2015', '10699210000173', '2015-04-30', 'Nota Fiscal', '4', 'DND TECNOLOGIA LTDA', '0000000363', '5105', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 159, 0, 159, 178948);
INSERT INTO despesas VALUES (5684565, '2015', '03842727000104', '2015-02-27', 'Nota Fiscal', '2', 'PRODUTEC', '000222', '5038', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 12000, 0, 12000, 178948);
INSERT INTO despesas VALUES (5618809, '2015', '10709560000173', '2015-03-04', 'Nota Fiscal', '3', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '110', '4946', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5645733, '2015', '10709560000173', '2015-04-02', 'Nota Fiscal', '4', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '120', '4987', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5670944, '2015', '10709560000173', '2015-05-04', 'Nota Fiscal', '5', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '131', '5022', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5708765, '2015', '10709560000173', '2015-06-08', 'Nota Fiscal', '6', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '140', '5060', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5731394, '2015', '10709560000173', '2015-07-07', 'Nota Fiscal', '7', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '152', '5091', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5755510, '2015', '10709560000173', '2015-08-06', 'Nota Fiscal', '8', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '161', '5115', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5784266, '2015', '10709560000173', '2015-09-04', 'Nota Fiscal', '9', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '171', '5147', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5807717, '2015', '10709560000173', '2015-10-01', 'Nota Fiscal', '10', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '180', '5175', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5837141, '2015', '10709560000173', '2015-11-04', 'Nota Fiscal', '11', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '189', '5215', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5866622, '2015', '10709560000173', '2015-12-03', 'Nota Fiscal', '12', 'VP PROCESSAMENTO DE DADOS E ASSESORIA TECNICA LTDA - ME', '198', '5252', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 8000, 0, 8000, 178948);
INSERT INTO despesas VALUES (5700895, '2015', '21738457000178', '2015-05-12', 'Nota Fiscal', '4', 'ARTHUR MORAIS DANTAS', '0000590572', '5049', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 178948);
INSERT INTO despesas VALUES (5745641, '2015', '21738457000178', '2015-05-13', 'Nota Fiscal', '5', 'ARTHUR MORAIS DANTAS', '0000591029', '5105', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 178948);
INSERT INTO despesas VALUES (5755502, '2015', '21738457000178', '2015-06-17', 'Nota Fiscal', '6', 'ARTHUR MORAIS DANTAS', '0000600633', '5115', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 178948);
INSERT INTO despesas VALUES (5763736, '2015', '21738457000178', '2015-07-13', 'Nota Fiscal', '7', 'ARTHUR MORAIS DANTAS', '0000608159', '5123', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 178948);
INSERT INTO despesas VALUES (5664699, '2015', '21738457000178', '2015-04-10', 'Nota Fiscal', '3', 'ARTHUR MORAIS DANTAS', '582042', '5012', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 178948);
INSERT INTO despesas VALUES (5700881, '2015', '02882661000113', '2015-05-18', 'Nota Fiscal', '5', 'ASSOC. COMUNITÁRIA, CULTURAL E ARTÍSTICA ITAJAENSE', '7456', '5049', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 300, 0, 300, 178948);
INSERT INTO despesas VALUES (5757731, '2015', '02882661000113', '2015-06-18', 'Nota Fiscal', '6', 'ASSOC. COMUNITÁRIA, CULTURAL E ARTÍSTICA ITAJAENSE', '7474', '5118', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 300, 0, 300, 178948);
INSERT INTO despesas VALUES (5838614, '2015', '02882661000113', '2015-10-19', 'Nota Fiscal', '9', 'ASSOC. COMUNITÁRIA, CULTURAL E ARTÍSTICA ITAJAENSE', '7535', '5216', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 600, 0, 600, 178948);
INSERT INTO despesas VALUES (5838621, '2015', '02882661000113', '2015-10-19', 'Nota Fiscal', '10', 'ASSOC. COMUNITÁRIA, CULTURAL E ARTÍSTICA ITAJAENSE', '7536', '5216', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 600, 0, 600, 178948);
INSERT INTO despesas VALUES (5886536, '2015', '02882661000113', '2015-12-09', 'Nota Fiscal', '11', 'ASSOC. COMUNITÁRIA, CULTURAL E ARTÍSTICA ITAJAENSE', '7570', '5291', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 300, 0, 0, 178948);
INSERT INTO despesas VALUES (1700775, '2009', '02128728428', '2009-10-01', 'Nota Fiscal', '10', 'CABO SERVIÇOS DE TELECOMUNICAÇÃO', '37763', '3105', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 163.800000000000011, 0, 163.800000000000011, 141428);
INSERT INTO despesas VALUES (1654851, '2009', '02952192000161', '2009-08-01', 'Nota Fiscal', '8', 'CABO SERVIÇOS DE TELECOMUNICAÇÃO', '36591', '3042', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 163.800000000000011, 0, 163.800000000000011, 141428);
INSERT INTO despesas VALUES (1648725, '2009', '02952192000161', '2009-07-01', 'Nota Fiscal', '7', 'CABO SERVIÇOS DE TELECOMUNICAÇÃO', '38203', '3017', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 167.22999999999999, 3.33000000000000007, 163.900000000000006, 141428);
INSERT INTO despesas VALUES (1720829, '2009', '02952192000161', '2009-11-01', 'Nota Fiscal', '11', 'CABO SERVIÇOS DE TELECOMUNICAÇÃO', '38339', '3130', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 163.800000000000011, 0, 163.800000000000011, 141428);
INSERT INTO despesas VALUES (1670734, '2009', '02952192000161', '2009-09-01', 'Nota Fiscal', '9', 'CABO SERVIÇOS DE TELECOMUNICAÇÃO LTDA', '37097', '3072', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 163.800000000000011, 0, 163.800000000000011, 141428);
INSERT INTO despesas VALUES (1629181, '2009', '04999366000177', '2009-07-15', 'Nota Fiscal', '7', 'CENTRO INTEGRADO DE TECNOLOGIA', '001642', '3067', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 141428);
INSERT INTO despesas VALUES (1706761, '2009', '04999366000177', '2009-08-17', 'Recibos/Outros', '8', 'CENTRO INTEGRADO DE TECNOLOGIA', '002144', '3116', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 141428);
INSERT INTO despesas VALUES (1706780, '2009', '04999366000177', '2009-09-15', 'Recibos/Outros', '9', 'CENTRO INTEGRADO DE TECNOLOGIA', '002145', '3116', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 141428);
INSERT INTO despesas VALUES (1706792, '2009', '04999366000177', '2009-10-15', 'Recibos/Outros', '10', 'CENTRO INTEGRADO DE TECNOLOGIA', '002146', '3116', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 141428);
INSERT INTO despesas VALUES (1599411, '2009', '20089627415', '2009-04-30', 'Recibos/Outros', '4', 'IRMA BARBALHO SIMONETI', 's/n', '2926', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1732.18000000000006, 0, 1732.18000000000006, 141428);
INSERT INTO despesas VALUES (1604569, '2009', '20089627415', '2009-05-31', 'Recibos/Outros', '5', 'IRMA BARBALHO SIMONETI', 's/n', '2941', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1732.18000000000006, 0, 1732.18000000000006, 141428);
INSERT INTO despesas VALUES (1620653, '2009', '20089627415', '2009-06-30', 'Recibos/Outros', '6', 'IRMA BARBALHO SIMONETI', 'S/N', '3018', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1732.18000000000006, 0, 1732.18000000000006, 141428);
INSERT INTO despesas VALUES (1720864, '2009', '20089627415', '2009-11-05', 'Recibos/Outros', '10', 'IRMA BARBALHO SIMONETI', 'S/N', '3147', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1736.18000000000006, 4, 1732.18000000000006, 141428);
INSERT INTO despesas VALUES (1654956, '2009', '20089627415', '2009-07-31', 'Recibos/Outros', '7', 'IRMA BARBALHO SIMONETI', 'S/Nº', '3061', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1732.18000000000006, 0, 1732.18000000000006, 141428);
INSERT INTO despesas VALUES (1693099, '2009', '20089627415', '2009-09-30', 'Recibos/Outros', '9', 'IRMA BARBALHO SIMONETTI', '09/2009', '3109', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1736.18000000000006, 0, 1736.18000000000006, 141428);
INSERT INTO despesas VALUES (1564744, '2009', '20089627415', '2009-03-31', 'Recibos/Outros', '3', 'IRMA BARBALHO SIMONETTI', 's/n', '2908', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1630, 0, 1630, 141428);
INSERT INTO despesas VALUES (1695171, '2009', '20089627415', '2009-09-05', 'Recibos/Outros', '8', 'IRMA BARBALHO SIMONETTI', 'S/Nº', '3095', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1732.18000000000006, 0, 1732.18000000000006, 141428);
INSERT INTO despesas VALUES (1649051, '2009', '10917975000132', '2009-08-11', 'Nota Fiscal', '8', 'RA PRODUÇÕES', '000012', '3025', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 3210, 0, 3210, 141428);
INSERT INTO despesas VALUES (1677051, '2009', '10917975000132', '2009-09-22', 'Nota Fiscal', '9', 'RA PRODUÇÕES', '000076', '3073', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 3210, 0, 3210, 141428);
INSERT INTO despesas VALUES (1705176, '2009', '10917975000132', '2009-10-27', 'Nota Fiscal', '10', 'RA PRODUÇÕES', '000103', '3110', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 3210, 0, 3210, 141428);
INSERT INTO despesas VALUES (1725654, '2009', '10917975000132', '2009-11-18', 'Nota Fiscal', '11', 'RA PRODUÇOES ', '000124', '3140', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 3210, 0, 3210, 141428);
INSERT INTO despesas VALUES (1638372, '2009', '33000118001655', '2009-07-01', 'Nota Fiscal', '6', 'TELEMAR', '00000001324', '3008', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 251.550000000000011, 0, 251.550000000000011, 141428);
INSERT INTO despesas VALUES (1638358, '2009', '33000118001655', '2009-06-22', 'Nota Fiscal', '6', 'TELEMAR', '00000177894', '3008', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1138.79999999999995, 18.5500000000000007, 1120.25, 141428);
INSERT INTO despesas VALUES (1638316, '2009', '33000118001655', '2009-06-22', 'Nota Fiscal', '6', 'TELEMAR', '00000177911', '3008', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 936.889999999999986, 6.70000000000000018, 930.190000000000055, 141428);
INSERT INTO despesas VALUES (1638421, '2009', '04206050005140', '2009-07-07', 'Nota Fiscal', '6', 'TIM', '00012018AB', '3013', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 3220.61999999999989, 0, 3220.61999999999989, 141428);
INSERT INTO despesas VALUES (1711430, '2009', '08399834000123', '2009-11-02', 'Nota Fiscal', '11', 'ALVARO DE OLIVEIRA', '088141', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 115.010000000000005, 0, 115.010000000000005, 141428);
INSERT INTO despesas VALUES (1588457, '2009', '08202116000115', '2009-04-01', 'Nota Fiscal', '4', 'AUTO POSTO AEROPORTO', '492510', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 35, 0, 35, 141428);
INSERT INTO despesas VALUES (1588460, '2009', '08202116000115', '2009-04-07', 'Nota Fiscal', '4', 'AUTO POSTO AEROPORTO', '495942', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711338, '2009', '08202116000115', '2009-09-01', 'Nota Fiscal', '9', 'AUTO POSTO AEROPORTO', '566942', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711400, '2009', '12753380000114', '2009-10-13', 'Nota Fiscal', '10', 'AUTO POSTO DUDU', '009069', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588507, '2009', '08202116000115', '2009-05-07', 'Nota Fiscal', '5', 'AUTP POSTO AEROPORTO', '499623', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711371, '2009', '00306597001411', '2009-09-22', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS', '010258', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 141428);
INSERT INTO despesas VALUES (1725634, '2009', '35304542000213', '2009-11-04', 'Nota Fiscal', '11', 'CIRNE PNEUS COMERCIO E SERVIÇOS LTDA', '00010238', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 458.470000000000027, 0, 458.470000000000027, 141428);
INSERT INTO despesas VALUES (1711876, '2009', '00373589000505', '2009-08-18', 'Nota Fiscal', '8', 'COMBUSTIVEIS AUTOMOTIVOS LTDA', '016434', '3118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141428);
INSERT INTO despesas VALUES (1711406, '2009', '01639447000178', '2009-10-17', 'Nota Fiscal', '10', 'COMERCIAL BARRA FORTE LTDA', '033121', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711316, '2009', '00038505000579', '2009-08-27', 'Nota Fiscal', '8', 'CONVER COMBUSTIVEIS', '134746', '3118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588505, '2009', '00038505000579', '2009-05-06', 'Nota Fiscal', '5', 'CONVER COMBUSTIVEIS AUTOMOTIVO', '0018279', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711871, '2009', '00038505000579', '2009-08-14', 'Nota Fiscal', '8', 'CONVER COMBUSTIVEIS AUTOMOTIVOS', '022166', '3118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1727155, '2009', '00038505000579', '2009-10-28', 'Nota Fiscal', '10', 'CONVER COMBUSTIVEIS AUTOMOTIVOS', '024474', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141428);
INSERT INTO despesas VALUES (1727142, '2009', '00038505000579', '2009-11-04', 'Nota Fiscal', '11', 'CONVER COMBUSTIVEIS AUTOMOTIVOS', '024762', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141428);
INSERT INTO despesas VALUES (1727150, '2009', '00038505000579', '2009-11-18', 'Nota Fiscal', '11', 'CONVER COMBUSTIVEIS AUTOMOTIVOS', '025209', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141428);
INSERT INTO despesas VALUES (1711357, '2009', '00038505000579', '2009-09-17', 'Nota Fiscal', '9', 'CONVER COMBUSTIVEIS AUTOMOTIVOS LTDA', '023473', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 141428);
INSERT INTO despesas VALUES (1727146, '2009', '00038505000579', '2009-11-11', 'Nota Fiscal', '11', 'CONVER COMBUSTIVEL AUTOMOTIVOS', '025003', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141428);
INSERT INTO despesas VALUES (1727145, '2009', '00038505000579', '2009-11-10', 'Nota Fiscal', '11', 'CONVER COMBUSTIVEL AUTOMOTIVOS', '136986', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141428);
INSERT INTO despesas VALUES (1711342, '2009', '00038505000579', '2009-09-02', 'Nota Fiscal', '9', 'COVER COMBUSTIVEIS AUTOMOTIVOS', '022900', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711346, '2009', '00038505000579', '2009-09-08', 'Nota Fiscal', '9', 'COVER COMBUSTIVEIS AUTOMOTIVOS', '023166', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1725642, '2009', '02829402000129', '2009-11-20', 'Nota Fiscal', '11', 'NATAL COMBUSTIVEIS LTDA', '230508', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 113.010000000000005, 0, 113.010000000000005, 141428);
INSERT INTO despesas VALUES (1588466, '2009', '08202116000115', '2009-04-14', 'Nota Fiscal', '4', 'POSTO AEROPORTO', '11510', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588475, '2009', '08202116000115', '2009-04-23', 'Nota Fiscal', '4', 'POSTO AEROPORTO', '11789', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588503, '2009', '08202116000115', '2009-05-01', 'Nota Fiscal', '5', 'POSTO AEROPORTO', '12173', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 28, 5.28000000000000025, 22.7199999999999989, 141428);
INSERT INTO despesas VALUES (1588504, '2009', '08202116000115', '2009-05-05', 'Nota Fiscal', '5', 'POSTO AEROPORTO', '12461', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1727148, '2009', '08202116000115', '2009-11-12', 'Nota Fiscal', '11', 'POSTO AEROPORTO', '15941', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141428);
INSERT INTO despesas VALUES (1711388, '2009', '35304542000213', '2009-10-08', 'Nota Fiscal', '10', 'POSTO CIRNE', '038982', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711393, '2009', '35304542000213', '2009-10-10', 'Nota Fiscal', '10', 'POSTO CIRNE', '128282', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588472, '2009', '04473193000159', '2009-04-17', 'Nota Fiscal', '4', 'POSTO DA TORRE', '005184', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588508, '2009', '04473193000159', '2009-05-11', 'Nota Fiscal', '5', 'POSTO DA TORRE', '014908', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588509, '2009', '04473193000159', '2009-05-13', 'Nota Fiscal', '5', 'POSTO DA TORRE', '015123', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588482, '2009', '04473193000159', '2009-04-23', 'Nota Fiscal', '4', 'POSTO DA TORRE', '017390', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 20, 0, 20, 141428);
INSERT INTO despesas VALUES (1588493, '2009', '04473193000159', '2009-04-29', 'Nota Fiscal', '4', 'POSTO DA TORRE', '034949', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588490, '2009', '04473193000159', '2009-04-29', 'Nota Fiscal', '4', 'POSTO DA TORRE', '035022', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588494, '2009', '04473193000159', '2009-04-30', 'Nota Fiscal', '4', 'POSTO DA TORRE', '035214', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711866, '2009', '04473193000159', '2009-08-08', 'Nota Fiscal', '8', 'POSTO DA TORRE', '043033', '3118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588469, '2009', '04473193000159', '2009-04-16', 'Nota Fiscal', '4', 'POSTO DA TORRE', '043057', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711310, '2009', '04473193000159', '2009-08-25', 'Nota Fiscal', '8', 'POSTO DA TORRE', '049848', '3118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588463, '2009', '04473193000159', '2009-04-08', 'Nota Fiscal', '4', 'POSTO DA TORRE', '538076', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141428);
INSERT INTO despesas VALUES (1711352, '2009', '04473193000159', '2009-09-11', 'Nota Fiscal', '9', 'POSTO DA TORRE LTDA', '023061', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711353, '2009', '04473193000159', '2009-09-15', 'Nota Fiscal', '9', 'POSTO DA TORRE LTDA', '033050', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1711302, '2009', '12689295000215', '2009-08-09', 'Nota Fiscal', '8', 'POSTO INTEGRAÇÃO', '031943', '3118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 90, 0, 90, 141428);
INSERT INTO despesas VALUES (1711364, '2009', '12689295000215', '2009-09-19', 'Nota Fiscal', '9', 'POSTO INTEGRAÇÃO', '040519', '3117', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1588486, '2009', '09136223000155', '2009-04-28', 'Nota Fiscal', '4', 'POSTO SÃO ROQUE', '314748', '2920', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141428);
INSERT INTO despesas VALUES (1599047, '2009', '04576059000183', '2009-05-21', 'Nota Fiscal', '5', 'MAXMEIO COMUNICAÇÃO ', '001648', '2928', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1599012, '2009', '04576059000183', '2009-05-21', 'Nota Fiscal', '4', 'MAXMEIO COMUNICAÇÃO', '001649', '2928', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1598973, '2009', '04576059000183', '2009-05-21', 'Nota Fiscal', '3', 'MAXMEIO COMUNICAÇÃO S/C LTDA', '001650', '2928', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1727139, '2009', '08423279000128', '2009-11-23', 'Nota Fiscal', '11', ' O JORNAL DE HOJE RN GRÁFICA E EDITORA LTDA', '26497', '3140', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 3000, 0, 3000, 141428);
INSERT INTO despesas VALUES (1672225, '2009', '02395290000145', '2009-09-03', 'Nota Fiscal', '8', 'ABOLIÇÃO FM LTDA', '001619', '3067', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 141428);
INSERT INTO despesas VALUES (1684386, '2009', '02395290000145', '2009-09-21', 'Nota Fiscal', '9', 'ABOLIÇÃO FM LTDA', '001639', '3089', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 141428);
INSERT INTO despesas VALUES (1711539, '2009', '02395290000145', '2009-10-23', 'Nota Fiscal', '10', 'ABOLIÇÃO FM LTDA', '001681', '3118', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1200, 0, 1200, 141428);
INSERT INTO despesas VALUES (1723228, '2009', '05359094000103', '2009-08-26', 'Nota Fiscal', '8', 'APPROACH', '5017', '3129', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 6752, 0, 6752, 141428);
INSERT INTO despesas VALUES (1599123, '2009', '08250946000118', '2009-05-25', 'Nota Fiscal', '5', 'DIFUSORA MOSSORÓ', '004594', '2928', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 600, 0, 600, 141428);
INSERT INTO despesas VALUES (1634830, '2009', '08250946000118', '2009-07-22', 'Nota Fiscal', '6', 'DIFUSORA MOSSORO', '004660', '3008', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 600, 0, 600, 141428);
INSERT INTO despesas VALUES (1634837, '2009', '08250946000118', '2009-07-22', 'Nota Fiscal', '7', 'DIFUSORA MOSSORÓ', '004661', '3009', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 600, 0, 600, 141428);
INSERT INTO despesas VALUES (1670775, '2009', '08250946000118', '2009-09-01', 'Nota Fiscal', '8', 'DIFUSORA MOSSORÓ', '004727', '3068', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 600, 0, 600, 141428);
INSERT INTO despesas VALUES (1715066, '2009', '08250946000118', '2009-11-04', 'Nota Fiscal', '10', 'DIFUSORA MOSSORÓ', '004787', '3122', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 600, 0, 600, 141428);
INSERT INTO despesas VALUES (1722531, '2009', '08562027000180', '2009-11-12', 'Nota Fiscal', '11', 'FM NORDESTE', '004074', '3129', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1000, 0, 1000, 141428);
INSERT INTO despesas VALUES (1599073, '2009', '08562027000180', '2009-05-18', 'Nota Fiscal', '5', 'FM NORDESTE LTDA', '003508', '2928', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 900, 0, 900, 141428);
INSERT INTO despesas VALUES (1608400, '2009', '08562027000180', '2009-06-09', 'Nota Fiscal', '6', 'FM NORDESTE LTDA', '003590', '2942', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1000, 0, 1000, 141428);
INSERT INTO despesas VALUES (1628752, '2009', '08562027000180', '2009-07-07', 'Nota Fiscal', '7', 'FM NORDESTE LTDA', '003697', '2982', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1000, 0, 1000, 141428);
INSERT INTO despesas VALUES (1652019, '2009', '08562027000180', '2009-08-11', 'Nota Fiscal', '8', 'FM NORDESTE LTDA', '003810', '3027', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1000, 0, 1000, 141428);
INSERT INTO despesas VALUES (1677044, '2009', '08562027000180', '2009-09-14', 'Nota Fiscal', '9', 'FM NORDESTE LTDA', '003906', '3076', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1000, 0, 1000, 141428);
INSERT INTO despesas VALUES (1700762, '2009', '08562027000180', '2009-10-13', 'Nota Fiscal', '10', 'FM NORDESTE LTDA', '003994', '3105', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1000, 0, 1000, 141428);
INSERT INTO despesas VALUES (1591320, '2009', '08385353000169', '2009-05-07', 'Nota Fiscal', '4', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011033', '2921', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1591355, '2009', '08385353000169', '2009-05-30', 'Nota Fiscal', '5', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011052', '2925', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1615027, '2009', '08385353000169', '2009-06-29', 'Nota Fiscal', '6', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011094', '2950', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1634839, '2009', '08385353000169', '2009-07-21', 'Nota Fiscal', '7', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011443', '3009', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1652027, '2009', '08385353000169', '2009-08-20', 'Nota Fiscal', '8', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011480', '3029', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1682598, '2009', '08385353000169', '2009-09-30', 'Nota Fiscal', '9', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011571', '3089', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1705175, '2009', '08385353000169', '2009-10-30', 'Nota Fiscal', '10', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011583', '3112', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1727137, '2009', '08385353000169', '2009-11-20', 'Nota Fiscal', '11', 'FUNDAÇÃO EDUCACIONAL SANTANA', '011961', '3140', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1628832, '2009', '04576059000183', '2009-06-17', 'Nota Fiscal', '6', 'MAXMEIO  COMUNICAÇÃO', '001712', '3008', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 3000, 0, 3000, 141428);
INSERT INTO despesas VALUES (1622051, '2009', '04576059000183', '2009-06-24', 'Nota Fiscal', '6', 'MAXMEIO COMUNICAÇÃO', '001746', '2960', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 500, 0, 500, 141428);
INSERT INTO despesas VALUES (1691288, '2009', '08729826000106', '2009-09-04', 'Recibos/Outros', '9', 'ABREU BRASIL BROKERS', '14869250000135292', '3089', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 586.210000000000036, 3, 583.210000000000036, 141429);
INSERT INTO despesas VALUES (1745981, '2009', '08729826000106', '2009-12-30', 'Recibos/Outros', '12', 'ABREU BRASIL BROKERS', 'S/N', '3156', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 586.210000000000036, 3, 583.210000000000036, 141429);
INSERT INTO despesas VALUES (1653333, '2009', '08729826000106', '2009-06-30', 'Recibos/Outros', '6', 'ABREU BRASIL BROKERS', 'SN', '3037', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 294.600000000000023, 0, 294.600000000000023, 141429);
INSERT INTO despesas VALUES (1653323, '2009', '08729826000106', '2009-07-30', 'Recibos/Outros', '7', 'ABREU BRASIL BROKERS', 'SN', '3036', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 586.210000000000036, 3, 583.210000000000036, 141429);
INSERT INTO despesas VALUES (1660761, '2009', '08729826000106', '2009-08-30', 'Recibos/Outros', '8', 'ABREU BRASIL BROKERS', 'SN', '3048', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 586.210000000000036, 3, 583.210000000000036, 141429);
INSERT INTO despesas VALUES (1758571, '2009', '08729826000106', '2009-12-30', 'Recibos/Outros', '12', 'ABREU BRASIL BROKERS', 'SN', '3202', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 586.210000000000036, 3, 583.210000000000036, 141429);
INSERT INTO despesas VALUES (1717627, '2009', '08729826000106', '2009-10-30', 'Recibos/Outros', '10', 'ABREU BRASILBROKERS', 'SN', '3124', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 586.210000000000036, 3, 583.210000000000036, 141429);
INSERT INTO despesas VALUES (1735216, '2009', '08729826000106', '2009-11-30', 'Recibos/Outros', '11', 'ABREU BRASILBROKERS', 'SN', '3145', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 586.210000000000036, 3, 583.210000000000036, 141429);
INSERT INTO despesas VALUES (1660794, '2009', '08070402000174', '2009-07-20', 'Recibos/Outros', '7', 'CONDOMÍNIO COMERCIAL BLUE TOWER', 'SN', '3048', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 169.430000000000007, 0, 169.430000000000007, 141429);
INSERT INTO despesas VALUES (1717638, '2009', '08070402000174', '2009-10-20', 'Recibos/Outros', '10', 'CONDOMÍNIO COMERCIAL BLUE TOWER', 'SN', '3124', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 173.780000000000001, 0, 173.780000000000001, 141429);
INSERT INTO despesas VALUES (1725515, '2009', '08070402000174', '2009-11-20', 'Recibos/Outros', '11', 'CONDOMÍNIO COMERCIAL BLUE TOWER', 'SN', '3139', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 169.430000000000007, 0, 169.430000000000007, 141429);
INSERT INTO despesas VALUES (1656346, '2009', '08324196000181', '2009-07-07', 'Nota Fiscal', '7', 'COSERN', '00000000000215863', '3040', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 13.5600000000000005, 0, 13.5600000000000005, 141429);
INSERT INTO despesas VALUES (1717640, '2009', '08324196000181', '2009-10-08', 'Nota Fiscal', '10', 'COSERN - COMPANHIA ENERGÉTICA RIO GRANDE DO NORTE', '000271821', '3124', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 13.5500000000000007, 0, 13.5500000000000007, 141429);
INSERT INTO despesas VALUES (1687359, '2009', '00540252000103', '2009-10-01', 'Nota Fiscal', '10', 'PAPELARIA ABC COMÉRCIO E INDÚSTRIA LTDA', '017598001', '3090', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 254.370000000000005, 19.0700000000000003, 235.300000000000011, 141429);
INSERT INTO despesas VALUES (1725502, '2009', '00540252000103', '2009-11-20', 'Nota Fiscal', '11', 'PAPELARIA ABC COMÉRCIO E INDÚSTRIA LTDA', '0180285/01', '3139', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 106.120000000000005, 42.7800000000000011, 63.3400000000000034, 141429);
INSERT INTO despesas VALUES (1742880, '2009', '00540252000103', '2009-12-15', 'Nota Fiscal', '12', 'PAPELARIA ABC COMÉRCIO E INDÚSTRIA LTDA', '0182311', '3156', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 288.45999999999998, 33.8999999999999986, 254.560000000000002, 141429);
INSERT INTO despesas VALUES (1742891, '2009', '04060009000220', '2009-12-12', 'Nota Fiscal', '12', 'TERRAÇO ZAPP PAPELARIA LTDA EPP', '0245', '3156', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 226.400000000000006, 0, 226.400000000000006, 141429);
INSERT INTO despesas VALUES (1618601, '2009', '01009686007076', '2009-06-07', 'Nota Fiscal', '6', 'TIM NORDESTE S/A', '6683ab', '2951', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1108.76999999999998, 19.9600000000000009, 1088.80999999999995, 141429);
INSERT INTO despesas VALUES (1572080, '2009', '06012706000150', '2009-04-08', 'Nota Fiscal', '4', 'CAMARÕES DO SERTÃO COMÉRCIO LTDA', '037946', '2897', 0, 'LOCOMOÇÃO, ALIMENTAÇÃO E  HOSPEDAGEM', '', 82.7199999999999989, 0, 82.7199999999999989, 141429);
INSERT INTO despesas VALUES (1572179, '2009', '06172269000131', '2009-04-01', 'Nota Fiscal', '4', 'CBB-FARIA LIMA ADM. HOTELEIRA E COMERCIAL LTDA', '00090502', '2897', 0, 'LOCOMOÇÃO, ALIMENTAÇÃO E  HOSPEDAGEM', '', 288.350000000000023, 0, 288.350000000000023, 141429);
INSERT INTO despesas VALUES (1623279, '2009', '08202116000115', '2009-06-23', 'Nota Fiscal', '6', 'AUTO POSTO AEROPORTO LTDA', '13558', '2965', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141429);
INSERT INTO despesas VALUES (1652296, '2009', '08202116000115', '2009-08-08', 'Nota Fiscal', '8', 'AUTO POSTO AEROPORTO LTDA', '14145', '3029', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 90, 0, 90, 141429);
INSERT INTO despesas VALUES (1717611, '2009', '08202116000115', '2009-11-03', 'Nota Fiscal', '11', 'AUTO POSTO AEROPORTO LTDA', '1938', '3124', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 62, 0, 62, 141429);
INSERT INTO despesas VALUES (1572097, '2009', '00814083000152', '2009-04-06', 'Nota Fiscal', '4', 'AUTO POSTO IMPERIAL', '459366', '2897', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1652300, '2009', '00814083000152', '2009-08-03', 'Nota Fiscal', '8', 'AUTO POSTO IMPERIAL', '469718', '3029', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1614093, '2009', '35304542000213', '2009-06-24', 'Nota Fiscal', '6', 'CIRNE PNEUS COMÉRCIO E INDÚSTRIA LTDA', '00008795', '2949', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3098.01000000000022, 0, 3098.01000000000022, 141429);
INSERT INTO despesas VALUES (1573486, '2009', '35304542000213', '2009-04-18', 'Nota Fiscal', '4', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00008226', '2897', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 2290, 0, 2290, 141429);
INSERT INTO despesas VALUES (1589037, '2009', '35304542000213', '2009-05-18', 'Nota Fiscal', '5', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00008455', '2919', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3205.69000000000005, 0, 3205.69000000000005, 141429);
INSERT INTO despesas VALUES (1631935, '2009', '35304542000213', '2009-07-20', 'Nota Fiscal', '7', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00009097', '2994', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 2980.63999999999987, 0, 2980.63999999999987, 141429);
INSERT INTO despesas VALUES (1656297, '2009', '35304542000213', '2009-08-19', 'Nota Fiscal', '8', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00009460', '3040', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3198.7800000000002, 0, 3198.7800000000002, 141429);
INSERT INTO despesas VALUES (1682704, '2009', '35304542000213', '2009-09-22', 'Nota Fiscal', '9', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00009782', '3085', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3204.01000000000022, 0, 3204.01000000000022, 141429);
INSERT INTO despesas VALUES (1706324, '2009', '35304542000213', '2009-10-16', 'Nota Fiscal', '10', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00010060', '3112', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3411.98999999999978, 0, 3411.98999999999978, 141429);
INSERT INTO despesas VALUES (1725352, '2009', '35304542000213', '2009-11-20', 'Nota Fiscal', '11', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00010418', '3135', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3423.05000000000018, 0, 3423.05000000000018, 141429);
INSERT INTO despesas VALUES (1725358, '2009', '35304542000213', '2009-11-23', 'Nota Fiscal', '11', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00010425', '3135', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 313.810000000000002, 0, 313.810000000000002, 141429);
INSERT INTO despesas VALUES (1742829, '2009', '35304542000213', '2009-12-14', 'Nota Fiscal', '12', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '00010636', '3156', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3539.32999999999993, 0, 3539.32999999999993, 141429);
INSERT INTO despesas VALUES (1682715, '2009', '00038505000145', '2009-09-01', 'Nota Fiscal', '9', 'CONVER COMBUSTÍVEIS AUTOMOTIVOS LTDA', '63055', '3085', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1741152, '2009', '00038505000145', '2009-11-24', 'Nota Fiscal', '11', 'CONVER COMBUSTÍVEIS AUTOMOTIVOS LTDA', '64610', '3153', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1602227, '2009', '02989654001197', '2009-06-01', 'Nota Fiscal', '6', 'MELHOR POSTO DE COMBUSTÍVEIS', '44918', '2932', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1639319, '2009', '02989654001197', '2009-07-15', 'Nota Fiscal', '7', 'MELHOR POSTO DE COMBUSTÍVEIS', '46502', '3009', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1741147, '2009', '02989654001197', '2009-12-01', 'Nota Fiscal', '12', 'MELHOR POSTO DE COMBUSTÍVEIS', '49243', '3153', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1717621, '2009', '02989654001197', '2009-10-26', 'Nota Fiscal', '10', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '27444', '3124', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141429);
INSERT INTO despesas VALUES (1589066, '2009', '02989654001197', '2009-04-28', 'Nota Fiscal', '4', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44042', '2919', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1589062, '2009', '02989654001197', '2009-04-16', 'Nota Fiscal', '4', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44153', '2919', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1572075, '2009', '02989654001197', '2009-04-14', 'Nota Fiscal', '4', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44284', '2897', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1613157, '2009', '02989654001197', '2009-06-05', 'Nota Fiscal', '6', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44613', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141429);
INSERT INTO despesas VALUES (1613160, '2009', '02989654001197', '2009-06-08', 'Nota Fiscal', '6', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44662', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1613161, '2009', '02989654001197', '2009-06-16', 'Nota Fiscal', '6', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44771', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141429);
INSERT INTO despesas VALUES (1623277, '2009', '02989654001197', '2009-06-24', 'Nota Fiscal', '6', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44867', '2965', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141429);
INSERT INTO despesas VALUES (1595321, '2009', '02989654001197', '2009-05-12', 'Nota Fiscal', '5', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '44975', '2927', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1652302, '2009', '02989654001197', '2009-08-12', 'Nota Fiscal', '8', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '46129', '3029', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1660768, '2009', '02989654001197', '2009-08-19', 'Nota Fiscal', '8', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '46707', '3048', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1682710, '2009', '02989654001197', '2009-09-28', 'Nota Fiscal', '9', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '47563', '3085', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1687340, '2009', '02989654001197', '2009-10-06', 'Nota Fiscal', '10', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '47864', '3090', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1717619, '2009', '02989654001197', '2009-10-13', 'Nota Fiscal', '10', 'MELHOR POSTO DE COMBUSTÍVEIS LTDA', '48216', '3124', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1742849, '2009', '08468795000179', '2009-12-13', 'Nota Fiscal', '12', 'ORGANIZAÇÃO MARTINS LTDA', '048931', '3156', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 116, 0, 116, 141429);
INSERT INTO despesas VALUES (1729057, '2009', '02072286000650', '2009-11-17', 'Nota Fiscal', '11', 'PETROIL COMBUSTÍVEIS', '003884', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 95, 0, 95, 141429);
INSERT INTO despesas VALUES (1717616, '2009', '00042044000184', '2009-10-22', 'Nota Fiscal', '10', 'POLAR DERIVADOS DE PETRÓLEO LTDA', '129462', '3124', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 62, 0, 62, 141429);
INSERT INTO despesas VALUES (1595328, '2009', '04473193000159', '2009-05-05', 'Nota Fiscal', '5', 'POSTO DA TORRE LTDA', '543923', '2927', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1663863, '2009', '04473193000159', '2009-08-26', 'Nota Fiscal', '8', 'POSTO DA TORRE LTDA', '556086', '3048', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141429);
INSERT INTO despesas VALUES (1613154, '2009', '07543171000106', '2009-06-22', 'Nota Fiscal', '6', 'POSTO FLORESTAL', '003466', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 128, 0, 128, 141429);
INSERT INTO despesas VALUES (1623284, '2009', '08350431000190', '2009-06-30', 'Nota Fiscal', '6', 'POSTO IMPERIAL', '001467', '2965', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 93.019999999999996, 0, 93.019999999999996, 141429);
INSERT INTO despesas VALUES (1589070, '2009', '40756983000377', '2009-05-02', 'Nota Fiscal', '5', 'POSTO OLINDA II', '207162', '2919', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 149.97999999999999, 0, 149.97999999999999, 141429);
INSERT INTO despesas VALUES (1676361, '2009', '02885153000199', '2009-09-10', 'Nota Fiscal', '9', 'VERDE AMARELO POSTO', '46627', '3076', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 141429);
INSERT INTO despesas VALUES (1572169, '2009', '02692183000189', '2009-04-16', 'Nota Fiscal', '4', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '03958', '2897', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 6000, 0, 6000, 141429);
INSERT INTO despesas VALUES (1589044, '2009', '02692183000189', '2009-05-14', 'Nota Fiscal', '5', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '04116', '2919', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 6000, 0, 6000, 141429);
INSERT INTO despesas VALUES (1613170, '2009', '02692183000189', '2009-06-17', 'Nota Fiscal', '6', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '04378', '2947', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 6000, 0, 6000, 141429);
INSERT INTO despesas VALUES (1631939, '2009', '02692183000189', '2009-07-01', 'Nota Fiscal', '7', 'ART&C COMUNICAÇÃO INTEGRADA LTDA ', '04557', '2994', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 6000, 0, 6000, 141429);
INSERT INTO despesas VALUES (1656306, '2009', '02692183000189', '2009-08-17', 'Nota Fiscal', '8', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '05162', '3040', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 6000, 0, 6000, 141429);
INSERT INTO despesas VALUES (1676356, '2009', '02692183000189', '2009-09-21', 'Nota Fiscal', '9', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '05320', '3073', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 12000, 0, 12000, 141429);
INSERT INTO despesas VALUES (1698676, '2009', '02692183000189', '2009-10-15', 'Nota Fiscal', '10', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '05421', '3099', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 6000, 0, 6000, 141429);
INSERT INTO despesas VALUES (1724854, '2009', '02692183000189', '2009-11-18', 'Nota Fiscal', '11', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '05565', '3132', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 6000, 0, 6000, 141429);
INSERT INTO despesas VALUES (1751141, '2009', '02692183000189', '2009-12-23', 'Nota Fiscal', '12', 'ART&C COMUNICAÇÃO INTEGRADA LTDA', '05767', '3173', 0, 'CONSULTORIAS, PESQUISAS E TRABALHOS TÉCNICOS.', '', 12000, 0, 12000, 141429);
INSERT INTO despesas VALUES (1561534, '2009', '24923872000190', '2009-03-25', 'Nota Fiscal', '3', 'DESAFIO PRODUÇÕES', '0020', '2889', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1574020, '2009', '24923872000190', '2009-04-16', 'Nota Fiscal', '4', 'DESAFIO PRODUÇÕES', '0025', '2905', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1758578, '2009', '11238855000171', '2009-12-10', 'Nota Fiscal', '12', 'HERNANE DE OLIVEIRA PINTO - ME', '0316', '3202', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1741160, '2009', '07695929000121', '2009-11-26', 'Nota Fiscal', '11', 'IMPRIMA EXPRESS GRÁFICA E COPIADORA LTDA ME', '2452', '3152', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 987, 0, 987, 141429);
INSERT INTO despesas VALUES (1602228, '2009', '10459013000187', '2009-05-29', 'Nota Fiscal', '5', 'JEFFERSON AUGUSTO MESQUITA - ME', '0493', '2932', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1623274, '2009', '10459013000187', '2009-06-26', 'Nota Fiscal', '6', 'JEFFERSON AUGUSTO MESQUITA - ME', '0595', '2965', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1651529, '2009', '10459013000187', '2009-08-04', 'Nota Fiscal', '8', 'JEFFERSON AUGUSTO MESQUITA - ME', '0759', '3025', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1667884, '2009', '10459013000187', '2009-09-02', 'Nota Fiscal', '9', 'JEFFERSON AUGUSTO MESQUITA - ME', '0897', '3056', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1687344, '2009', '10459013000187', '2009-10-01', 'Nota Fiscal', '9', 'JEFFERSON AUGUSTO MESQUITA - ME', '1054', '3090', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1725477, '2009', '10459013000187', '2009-11-24', 'Nota Fiscal', '11', 'JEFFERSON AUGUSTO MESQUITA - ME', '1168', '3132', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1702342, '2009', '07451335000175', '2009-10-21', 'Nota Fiscal', '10', 'POOL MIX DE SOLUÇÕES', '0750', '3107', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1500, 0, 1500, 141429);
INSERT INTO despesas VALUES (1675261, '2009', '40782161000107', '2009-08-20', 'Nota Fiscal', '8', 'RHENANA DE ARAUJO HACKRADT - ME', '003845', '3065', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 2500, 0, 2500, 141429);
INSERT INTO despesas VALUES (1674142, '2009', '02749278000191', '2009-08-14', 'Nota Fiscal', '8', 'UNIGRÁFICA - GRÁFICA E EDITORA LTDA - EPP', '007830', '3067', 0, 'DIVULGAÇÃO DA ATIVIDADE PARLAMENTAR.', '', 1580, 0, 1580, 141429);
INSERT INTO despesas VALUES (1589079, '2009', '00540252000103', '2009-05-04', 'Nota Fiscal', '5', 'PAPELARIA ABC COMÉRCIO E INDÚSTRIA LTDA', '0161946', '2919', 0, 'AQUISIÇÃO DE MATERIAL DE ESCRITÓRIO.', '', 297.089999999999975, 114.719999999999999, 182.370000000000005, 141429);
INSERT INTO despesas VALUES (1613164, '2009', '00540252000103', '2009-06-12', 'Nota Fiscal', '6', 'PAPELARIA ABC COMÉRCIO E INDÚSTRIA LTDA', '0165589', '2947', 0, 'AQUISIÇÃO DE MATERIAL DE ESCRITÓRIO.', '', 287.949999999999989, 135.990000000000009, 151.960000000000008, 141429);
INSERT INTO despesas VALUES (1745410, '2009', '02012862000160', '2009-07-21', 'Nota Fiscal', '7', 'TAM LINHAS AÉREAS S.A.', '9572366626161', '3152', 0, 'PASSAGENS AÉREAS', '', 822.07000000000005, 0, 822.07000000000005, 141429);
INSERT INTO despesas VALUES (1696721, '2009', '66970229000167', '2009-09-16', 'Nota Fiscal', '9', 'NEXTEL TELECOMINICAÇÕES LTDA', '000005285', '3105', 0, 'TELEFONIA', '', 242.370000000000005, 0, 242.370000000000005, 141429);
INSERT INTO despesas VALUES (1674158, '2009', '66970229000167', '2009-08-16', 'Nota Fiscal', '8', 'NEXTEL TELECOMUNICAÇÕES LTDA', '000005021', '3067', 0, 'TELEFONIA', '', 256.579999999999984, 0, 256.579999999999984, 141429);
INSERT INTO despesas VALUES (1719132, '2009', '66970229000167', '2009-10-16', 'Nota Fiscal', '10', 'NEXTEL TELECOMUNICAÇÕES LTDA', '000006507', '3128', 0, 'TELEFONIA', '', 246.949999999999989, 5.29999999999999982, 241.650000000000006, 141429);
INSERT INTO despesas VALUES (1758577, '2009', '66970229000167', '2009-12-17', 'Nota Fiscal', '12', 'NEXTEL TELECOMUNICAÇÕES LTDA', '000007614', '3202', 0, 'TELEFONIA', '', 241.699999999999989, 0, 241.699999999999989, 141429);
INSERT INTO despesas VALUES (1742861, '2009', '66970229001805', '2009-11-15', 'Nota Fiscal', '11', 'NEXTEL TELECOMUNICAÇÕES LTDA', '000005863', '3156', 0, 'TELEFONIA', '', 245.930000000000007, 4.92999999999999972, 241, 141429);
INSERT INTO despesas VALUES (5608047, '2015', '05654704000100', '2015-02-02', 'Nota Fiscal', '2', 'CASA DAS ARTES', '2281', '4934', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 797.850000000000023, 0, 797.850000000000023, 178951);
INSERT INTO despesas VALUES (5687037, '2015', '00670562000142', '2015-05-13', 'Nota Fiscal', '5', 'CASA DO COLEGIAL LIVRARIA E PAPELARIA LTDA', '009098', '5039', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 98.5, 0, 98.5, 178951);
INSERT INTO despesas VALUES (5749179, '2015', '40432544007826', '2015-07-01', 'Nota Fiscal', '7', 'CLARO S/A', '000002520', '5110', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 84.5999999999999943, 0, 84.5999999999999943, 178951);
INSERT INTO despesas VALUES (5767404, '2015', '00664435000130', '2015-07-22', 'Recibos/Outros', '7', 'CONDOMÍNIO ESPAÇO EMPRESARIAL GIOVANNI FULCO', '07/2015', '5129', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 455.089999999999975, 0, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5829700, '2015', '00664435000130', '2015-10-21', 'Recibos/Outros', '10', 'CONDOMÍNIO ESPAÇO EMPRESARIAL GIOVANNI FULCO', '10/2015', '5212', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 464.79000000000002, 9.69999999999999929, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5905143, '2015', '00664435000130', '2016-02-02', 'Recibos/Outros', '11', 'CONDOMÍNIO ESPAÇO EMPRESARIAL GIOVANNI FULCO', '11/2015', '5321', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 475.449999999999989, 20.3599999999999994, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5896081, '2015', '00664435000130', '2015-12-09', 'Nota Fiscal', '12', 'CONDOMÍNIO ESPAÇO EMPRESARIAL GIOVANNI FULCO', '12/2015', '5313', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 465.839999999999975, 0, 465.839999999999975, 178951);
INSERT INTO despesas VALUES (5774194, '2015', '00664435000130', '2015-08-26', 'Recibos/Outros', '8', 'CONDOMÍNIO ESPAÇO EMPRESARIAL GIOVANNI FULCO', '903/082015', '5134', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 464.490000000000009, 9.40000000000000036, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5813102, '2015', '00664435000130', '2015-10-06', 'Recibos/Outros', '9', 'CONDOMÍNIO ESPAÇO EMPRESARIAL GIOVANNI FULCO', 's/n', '5189', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 466.889999999999986, 11.8000000000000007, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5668911, '2015', '08324196000181', '2015-03-24', 'Nota Fiscal', '3', 'COSERN', '001054196', '5019', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 618.730000000000018, 5.12999999999999989, 613.600000000000023, 178951);
INSERT INTO despesas VALUES (5636782, '2015', '08324196000181', '2015-02-23', 'Nota Fiscal', '2', 'COSERN', '0010622365', '4974', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 245, 6.00999999999999979, 238.990000000000009, 178951);
INSERT INTO despesas VALUES (5871299, '2015', '08324196000181', '2015-10-23', 'Nota Fiscal', '10', 'COSERN', '001077012', '5262', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 493.550000000000011, 0, 493.550000000000011, 178951);
INSERT INTO despesas VALUES (5774183, '2015', '08324196000181', '2015-07-23', 'Nota Fiscal', '7', 'COSERN', '001078243', '5133', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 239.620000000000005, 0, 239.620000000000005, 178951);
INSERT INTO despesas VALUES (5801283, '2015', '08324196000181', '2015-08-24', 'Nota Fiscal', '8', 'COSERN', '001082601', '5169', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 299.060000000000002, 0, 299.060000000000002, 178951);
INSERT INTO despesas VALUES (5829718, '2015', '08324196000181', '2015-09-22', 'Nota Fiscal', '9', 'COSERN', '001083686', '5212', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 338.519999999999982, 4.70000000000000018, 333.819999999999993, 178951);
INSERT INTO despesas VALUES (5894492, '2015', '08324196000181', '2015-11-24', 'Nota Fiscal', '11', 'COSERN', '001111980', '5313', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 338.230000000000018, 6.24000000000000021, 331.990000000000009, 178951);
INSERT INTO despesas VALUES (5922353, '2015', '08324196000181', '2015-12-23', 'Nota Fiscal', '12', 'COSERN', '001123729', '5387', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 442.20999999999998, 11.1799999999999997, 431.029999999999973, 178951);
INSERT INTO despesas VALUES (5743844, '2015', '08324196000181', '2015-06-23', 'Nota Fiscal', '6', 'COSERN', '001140706', '5110', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 311.529999999999973, 11.5899999999999999, 299.939999999999998, 178951);
INSERT INTO despesas VALUES (5721560, '2015', '08324196000181', '2015-05-25', 'Nota Fiscal', '5', 'COSERN', '001156033', '5080', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 490.829999999999984, 0, 490.829999999999984, 178951);
INSERT INTO despesas VALUES (5700657, '2015', '08324196000181', '2015-04-23', 'Nota Fiscal', '4', 'COSERN', '001207655', '5049', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 396.870000000000005, 0, 396.870000000000005, 178951);
INSERT INTO despesas VALUES (5668927, '2015', '08324196000181', '2015-03-30', 'Nota Fiscal', '3', 'COSERN', '001330009', '5019', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 14.0199999999999996, 0, 14.0199999999999996, 178951);
INSERT INTO despesas VALUES (5871221, '2015', '26499624000199', '2015-12-06', 'Nota Fiscal', '12', 'MARIA DAS DORES SILVA EPP', '095237', '5261', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 39.8999999999999986, 0, 39.8999999999999986, 178951);
INSERT INTO despesas VALUES (5608666, '2015', '19353883000141', '2015-02-23', 'Recibos/Outros', '2', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0001/2015', '4934', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5608714, '2015', '19353883000141', '2015-02-23', 'Recibos/Outros', '2', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0002/2015', '4934', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 603.610000000000014, 0, 603.610000000000014, 178951);
INSERT INTO despesas VALUES (5673517, '2015', '19353883000141', '2015-04-06', 'Recibos/Outros', '4', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0003/2015', '5031', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5687069, '2015', '19353883000141', '2015-05-05', 'Recibos/Outros', '5', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0004/2015', '5039', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5721583, '2015', '19353883000141', '2015-06-05', 'Recibos/Outros', '6', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0005/2015', '5074', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5743824, '2015', '19353883000141', '2015-07-06', 'Recibos/Outros', '7', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0006/2015', '5110', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5767359, '2015', '19353883000141', '2015-08-05', 'Recibos/Outros', '8', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0007/2015', '5129', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5825275, '2015', '19353883000141', '2015-09-05', 'Recibos/Outros', '9', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0008/2015', '5202', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5825272, '2015', '19353883000141', '2015-10-05', 'Recibos/Outros', '10', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0009/2015', '5202', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5837923, '2015', '19353883000141', '2015-11-05', 'Recibos/Outros', '11', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0010/2015', '5240', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5880156, '2015', '19353883000141', '2015-12-07', 'Recibos/Outros', '12', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '0011/2015', '5284', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5636790, '2015', '19353883000141', '2015-03-13', 'Recibos/Outros', '3', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '002/2015', '4974', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2500, 0, 2500, 178951);
INSERT INTO despesas VALUES (5608676, '2015', '19353883000141', '2015-02-18', 'Recibos/Outros', '2', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '02/2015', '4934', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 455.089999999999975, 0, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5637405, '2015', '19353883000141', '2015-03-13', 'Recibos/Outros', '3', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '03/2015', '4974', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 455.089999999999975, 0, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5669005, '2015', '19353883000141', '2015-04-18', 'Recibos/Outros', '4', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '04/2015', '5019', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 455.089999999999975, 0, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5713049, '2015', '19353883000141', '2015-05-11', 'Recibos/Outros', '5', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '05/2015', '5068', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 455.089999999999975, 0, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5721594, '2015', '19353883000141', '2015-06-18', 'Recibos/Outros', '6', 'MENQ EMPREENDIMENTOS IMOBILIÁRIOS LTDA', '06/2015', '5075', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 455.089999999999975, 0, 455.089999999999975, 178951);
INSERT INTO despesas VALUES (5626634, '2015', '08473985000184', '2015-02-26', 'Nota Fiscal', '2', 'Alvares & Alvares Ltda', '500161', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178951);
INSERT INTO despesas VALUES (5647357, '2015', '08473985000184', '2015-03-17', 'Nota Fiscal', '3', 'Alvares & Alvares Ltda', '511969', '4993', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 122.439999999999998, 0, 122.439999999999998, 178951);
INSERT INTO despesas VALUES (5658396, '2015', '08202116000115', '2015-04-14', 'Nota Fiscal', '4', 'Auto Posto Aeroporto Ltda', '413166', '5004', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 172.009999999999991, 0, 172.009999999999991, 178951);
INSERT INTO despesas VALUES (5673434, '2015', '08202116000115', '2015-05-04', 'Nota Fiscal', '4', 'AUTO POSTO AEROPORTO LTDA.', '54464', '5031', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 196.710000000000008, 0, 196.710000000000008, 178951);
INSERT INTO despesas VALUES (5636774, '2015', '00692418000107', '2015-03-24', 'Nota Fiscal', '3', 'AUTO POSTO CINCO ESTRELAS LTDA', '112576', '4974', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 118.459999999999994, 0, 118.459999999999994, 178951);
INSERT INTO despesas VALUES (5784506, '2015', '00365320000145', '2015-08-27', 'Nota Fiscal', '8', 'AUTO POSTO ESPLANADA LTDA', '250807', '5148', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5608043, '2015', '02731610000271', '2015-02-05', 'Nota Fiscal', '2', 'AUTO POSTO ITICAR LTDA', '375158', '4934', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 133.139999999999986, 0, 133.139999999999986, 178951);
INSERT INTO despesas VALUES (5608645, '2015', '05000684000226', '2015-02-24', 'Nota Fiscal', '2', 'AUTO POSTO PETER PAN 01 LTDA', '701959', '4934', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 105.959999999999994, 0, 105.959999999999994, 178951);
INSERT INTO despesas VALUES (5626620, '2015', '05000684000226', '2015-03-04', 'Nota Fiscal', '3', 'AUTO POSTO PETER PAN 01 LTDA', '709084', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 117.109999999999999, 0, 117.109999999999999, 178951);
INSERT INTO despesas VALUES (5626623, '2015', '05000684000226', '2015-03-10', 'Nota Fiscal', '3', 'AUTO POSTO PETER PAN 01 LTDA', '714469', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 96.019999999999996, 0, 96.019999999999996, 178951);
INSERT INTO despesas VALUES (5647457, '2015', '05000684000226', '2015-03-30', 'Nota Fiscal', '3', 'AUTO POSTO PETER PAN 01 LTDA', '732193', '4993', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 111.189999999999998, 0, 111.189999999999998, 178951);
INSERT INTO despesas VALUES (5647351, '2015', '05000684000226', '2015-03-31', 'Nota Fiscal', '3', 'AUTO POSTO PETER PAN 01 LTDA', '732615', '4993', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 175.77000000000001, 0, 175.77000000000001, 178951);
INSERT INTO despesas VALUES (5658393, '2015', '05000684000226', '2015-04-08', 'Nota Fiscal', '4', 'AUTO POSTO PETER PAN 01 LTDA', '738910', '5004', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 110.040000000000006, 0, 110.040000000000006, 178951);
INSERT INTO despesas VALUES (5829733, '2015', '05000684000226', '2015-10-27', 'Nota Fiscal', '10', 'AUTO POSTO PETER PAN 01 LTDA', '889073', '5212', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5871241, '2015', '05000684000226', '2015-12-02', 'Nota Fiscal', '12', 'AUTO POSTO PETER PAN 01 LTDA', '915131', '5261', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178951);
INSERT INTO despesas VALUES (5880126, '2015', '05000684000226', '2015-12-11', 'Nota Fiscal', '12', 'AUTO POSTO PETER PAN 01 LTDA', '921093', '5285', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178951);
INSERT INTO despesas VALUES (5880107, '2015', '05000684000226', '2015-12-14', 'Nota Fiscal', '12', 'AUTO POSTO PETER PAN 01 LTDA', '923204', '5285', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5858009, '2015', '05000684000226', '2015-11-24', 'Nota Fiscal', '11', 'AUTO POSTO PETER PAN 01 LTDA', '92439', '5245', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5880122, '2015', '00306597000440', '2015-12-14', 'Nota Fiscal', '12', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA', '021288', '5285', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 149.25, 0, 149.25, 178951);
INSERT INTO despesas VALUES (5636773, '2015', '00306597003112', '2015-03-17', 'Nota Fiscal', '3', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '030716', '4974', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 118.099999999999994, 0, 118.099999999999994, 178951);
INSERT INTO despesas VALUES (5687201, '2015', '00306597003112', '2015-05-16', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '033481', '5039', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178951);
INSERT INTO despesas VALUES (5737027, '2015', '00306597003112', '2015-07-09', 'Nota Fiscal', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '036041', '5094', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178951);
INSERT INTO despesas VALUES (5767391, '2015', '00306597003112', '2015-08-13', 'Nota Fiscal', '8', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '037696', '5129', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 185.629999999999995, 0, 185.629999999999995, 178951);
INSERT INTO despesas VALUES (5784498, '2015', '00306597003112', '2015-09-02', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '038769', '5148', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5784486, '2015', '00306597003112', '2015-09-03', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '038840', '5148', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178951);
INSERT INTO despesas VALUES (5801215, '2015', '00306597003112', '2015-09-22', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '039630', '5169', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 180, 0, 180, 178951);
INSERT INTO despesas VALUES (5825243, '2015', '00306597003112', '2015-10-20', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '040823', '5201', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5844857, '2015', '00306597003112', '2015-11-10', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '041742', '5228', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 131.240000000000009, 0, 131.240000000000009, 178951);
INSERT INTO despesas VALUES (5851788, '2015', '00306597003112', '2015-11-17', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '042067', '5245', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5858013, '2015', '00306597003112', '2015-11-19', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '042167', '5245', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178951);
INSERT INTO despesas VALUES (5871598, '2015', '00306597003112', '2015-12-09', 'Nota Fiscal', '12', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '042963', '5261', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178951);
INSERT INTO despesas VALUES (5721555, '2015', '00306597003112', '2015-06-29', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '17196', '5080', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178951);
INSERT INTO despesas VALUES (5829739, '2015', '00306597003112', '2015-10-27', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '19089', '5212', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 160.879999999999995, 0, 160.879999999999995, 178951);
INSERT INTO despesas VALUES (5873146, '2015', '00306597003112', '2015-12-07', 'Nota Fiscal', '12', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '19407', '5261', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 190.719999999999999, 0, 190.719999999999999, 178951);
INSERT INTO despesas VALUES (5812800, '2015', '00306597005085', '2015-09-30', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '20146', '5201', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5768274, '2015', '00306597007614', '2015-08-19', 'Nota Fiscal', '8', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '26240', '5129', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 195.099999999999994, 0, 195.099999999999994, 178951);
INSERT INTO despesas VALUES (5894655, '2015', '00306597006723', '2015-12-23', 'Nota Fiscal', '12', 'CASCOL COMBUSTÍVEIS PARA VEÍVULOS LTDA', '46738', '5319', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 178951);
INSERT INTO despesas VALUES (5700539, '2015', '04652899000188', '2015-04-10', 'Nota Fiscal', '4', 'CAVALCANTE & ROCHA LTDA - POSTO AREZ', '118852', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 151.5, 0, 151.5, 178951);
INSERT INTO despesas VALUES (5786261, '2015', '11786705000100', '2015-08-19', 'Nota Fiscal', '8', 'CIAS COM. VAREJISTA DE COMB. LTDA', '555895', '5148', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 123.370000000000005, 0, 123.370000000000005, 178951);
INSERT INTO despesas VALUES (5608641, '2015', '35304542000990', '2015-02-18', 'Nota Fiscal', '2', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '303762', '4934', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178951);
INSERT INTO despesas VALUES (5608644, '2015', '35304542000990', '2015-02-23', 'Nota Fiscal', '2', 'CIRNE PNEUS COMÉRCIO E SERVIÇOS LTDA', '400834', '4934', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 170.669999999999987, 0, 170.669999999999987, 178951);
INSERT INTO despesas VALUES (5737046, '2015', '35304542001376', '2015-06-30', 'Nota Fiscal', '6', 'Cirne Pneus Comercio e Serviços Ltda', '228183', '5094', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 70, 0, 70, 178951);
INSERT INTO despesas VALUES (5700591, '2015', '10702904000112', '2015-05-21', 'Nota Fiscal', '5', 'COMERCIAL DE COMBUSTÍVEIS MAM LTDA', '179517', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 177, 0, 177, 178951);
INSERT INTO despesas VALUES (5825246, '2015', '00001388000226', '2015-10-21', 'Nota Fiscal', '10', 'DISTRIBUIDORA BRASILIA DE VEICULOS S/A - Posto Disbrave', '344272', '5201', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5844865, '2015', '00001388000226', '2015-11-10', 'Nota Fiscal', '11', 'DISTRIBUIDORA BRASILIA DE VEICULOS S/A - Posto Disbrave', '349426', '5228', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5837525, '2015', '00001388000226', '2015-11-03', 'Nota Fiscal', '11', 'DISTRIBUIDORA BRASILIA DE VEICULOS S/A - Posto Disbrave', '505344', '5216', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5749492, '2015', '07615434000145', '2015-07-22', 'Nota Fiscal', '7', 'HSI DISTRIBUIDORA DE COMBUSTÍVEL LTDA', '355065', '5110', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 74.480000000000004, 0, 74.480000000000004, 178951);
INSERT INTO despesas VALUES (5786253, '2015', '70318951000199', '2015-09-01', 'Nota Fiscal', '9', 'JAGUARARI POSTO', '570457', '5148', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178951);
INSERT INTO despesas VALUES (5668820, '2015', '03469182000566', '2015-04-28', 'Nota Fiscal', '4', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '164748', '5019', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 115.340000000000003, 0, 115.340000000000003, 178951);
INSERT INTO despesas VALUES (5687018, '2015', '03469182000566', '2015-05-13', 'Nota Fiscal', '5', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '167355', '5039', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 176.710000000000008, 0, 176.710000000000008, 178951);
INSERT INTO despesas VALUES (5687027, '2015', '03469182000566', '2015-05-18', 'Nota Fiscal', '5', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '168203', '5039', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 190.050000000000011, 0, 190.050000000000011, 178951);
INSERT INTO despesas VALUES (5700524, '2015', '03469182000566', '2015-05-25', 'Nota Fiscal', '5', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '169373', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 175.669999999999987, 0, 175.669999999999987, 178951);
INSERT INTO despesas VALUES (5700490, '2015', '03469182000566', '2015-06-01', 'Nota Fiscal', '6', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '170538', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178951);
INSERT INTO despesas VALUES (5713011, '2015', '03469182000566', '2015-06-10', 'Nota Fiscal', '6', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '171943', '5064', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (5713023, '2015', '03469182000566', '2015-06-15', 'Nota Fiscal', '6', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '172901', '5064', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 143.139999999999986, 0, 143.139999999999986, 178951);
INSERT INTO despesas VALUES (5721557, '2015', '03469182000566', '2015-06-26', 'Nota Fiscal', '6', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '174841', '5075', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 110, 0, 110, 178951);
INSERT INTO despesas VALUES (5731187, '2015', '03469182000566', '2015-07-07', 'Nota Fiscal', '7', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '176558', '5089', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 130, 0, 130, 178951);
INSERT INTO despesas VALUES (5737003, '2015', '03469182000566', '2015-07-13', 'Nota Fiscal', '7', 'JJS COMERCIO DE COMBUSTIVEIS LTDA', '177513', '5094', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178951);
INSERT INTO despesas VALUES (1615642, '2009', '08729826000106', '2009-06-25', 'Recibos/Outros', '6', 'ABREU  BRASIL BROKERS', 'S/N', '2948', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1761, 3, 1758, 141535);
INSERT INTO despesas VALUES (1707968, '2009', '08729826000106', '2009-10-30', 'Recibos/Outros', '10', 'ABREU IMOVEIS', '11', '3115', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2003, 3, 2000, 141535);
INSERT INTO despesas VALUES (1575017, '2009', '08729826000106', '2009-04-30', 'Recibos/Outros', '4', 'ABREU IMOVEIS', 'S/N', '2900', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1761.02999999999997, 3, 1758.02999999999997, 141535);
INSERT INTO despesas VALUES (1598470, '2009', '08729826000106', '2009-05-30', 'Recibos/Outros', '5', 'ABREU IMOVEIS', 'S/N', '2929', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1761.02999999999997, 3, 1758.02999999999997, 141535);
INSERT INTO despesas VALUES (1730245, '2009', '08729826000106', '2009-11-30', 'Recibos/Outros', '11', 'ABREU IMOVEIS', 'S/N', '3140', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2003, 3, 2000, 141535);
INSERT INTO despesas VALUES (1665813, '2009', '08729826000106', '2009-08-30', 'Nota Fiscal', '8', 'ABREU IMOVEIS', 'SN', '3056', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2003, 3, 2000, 141535);
INSERT INTO despesas VALUES (1635365, '2009', '08729826000106', '2009-07-30', 'Recibos/Outros', '7', 'ABREU IMOVEIS', 'SN', '3004', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1761.02999999999997, 3, 1758.02999999999997, 141535);
INSERT INTO despesas VALUES (1685827, '2009', '08729826000106', '2009-09-30', 'Recibos/Outros', '9', 'ABREU IMOVEL', '5685', '3090', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 2003, 3, 2000, 141535);
INSERT INTO despesas VALUES (1635368, '2009', '02952192000161', '2009-08-01', 'Nota Fiscal', '8', 'CABOTELECOM', '3933', '3004', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 134.22999999999999, 0, 134.22999999999999, 141535);
INSERT INTO despesas VALUES (1665821, '2009', '02952192000161', '2009-09-01', 'Nota Fiscal', '9', 'CABOTELECOM', '4073', '3058', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 134.22999999999999, 0, 134.22999999999999, 141535);
INSERT INTO despesas VALUES (1687392, '2009', '02952192000161', '2009-10-01', 'Nota Fiscal', '10', 'CABOTELECOM', '4209', '3090', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 134.22999999999999, 0, 134.22999999999999, 141535);
INSERT INTO despesas VALUES (1740841, '2009', '02952192000161', '2009-12-01', 'Nota Fiscal', '12', 'CABOTELECOM', '4234', '3152', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 134.22999999999999, 0, 134.22999999999999, 141535);
INSERT INTO despesas VALUES (1685812, '2009', '00019299000126', '2009-10-01', 'Nota Fiscal', '10', 'COMERCIAL PAPIROS LTDA', '048195', '3090', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 175, 0, 175, 141535);
INSERT INTO despesas VALUES (1584753, '2009', '08324196000181', '2009-04-14', 'Nota Fiscal', '4', 'COSERN', '00000000000393839', '2913', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 808.049999999999955, 0, 808.049999999999955, 141535);
INSERT INTO despesas VALUES (1593628, '2009', '08324196000181', '2009-05-13', 'Nota Fiscal', '5', 'COSERN', '00000000000396683', '2925', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 764.940000000000055, 16.3000000000000007, 748.639999999999986, 141535);
INSERT INTO despesas VALUES (1687343, '2009', '10266923000143', '2009-10-05', 'Nota Fiscal', '10', 'G. TEC. INFORMÁTICA', '000021', '3090', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1270, 0, 1270, 141535);
INSERT INTO despesas VALUES (1564152, '2009', '33000118000179', '2009-03-19', 'Nota Fiscal', '3', 'OI FIXO', '76523', '2888', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 527.299999999999955, 18.1000000000000014, 509.199999999999989, 141535);
INSERT INTO despesas VALUES (1615605, '2009', '33000118001655', '2009-06-18', 'Nota Fiscal', '6', 'TELEMAR NORTE LESTE S/A ', '00000081206', '2948', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 783.019999999999982, 6.46999999999999975, 776.549999999999955, 141535);
INSERT INTO despesas VALUES (1579894, '2009', '01009686007076', '2009-04-19', 'Nota Fiscal', '4', 'TIM', '018589AB', '2905', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 435.220000000000027, 0, 435.220000000000027, 141535);
INSERT INTO despesas VALUES (1571262, '2009', '01009686007076', '2009-03-19', 'Nota Fiscal', '3', 'TIM', '019410AB', '2895', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 724.279999999999973, 1.98999999999999999, 722.289999999999964, 141535);
INSERT INTO despesas VALUES (1620941, '2009', '01009686007076', '2009-06-19', 'Nota Fiscal', '6', 'TIM NORDESTE S.A.', '21187AB', '2965', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 445.740000000000009, 0, 445.740000000000009, 141535);
INSERT INTO despesas VALUES (1571528, '2009', '07712760000170', '2009-04-21', 'Nota Fiscal', '4', 'MAGALY VASCONCELOS DOS SANTOS - ME', '001371', '2896', 0, 'LOCOMOÇÃO, ALIMENTAÇÃO E  HOSPEDAGEM', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1571521, '2009', '46553947000120', '2009-04-16', 'Recibos/Outros', '4', 'RÁDIO TÁXI', '564785', '2896', 0, 'LOCOMOÇÃO, ALIMENTAÇÃO E  HOSPEDAGEM', '', 27, 0, 27, 141535);
INSERT INTO despesas VALUES (1615534, '2009', '36095792000172', '2009-06-24', 'Recibos/Outros', '6', 'TRANSCOOTOUR TAXI ESPECIAL', '508650', '2948', 0, 'LOCOMOÇÃO, ALIMENTAÇÃO E  HOSPEDAGEM', '', 37, 0, 37, 141535);
INSERT INTO despesas VALUES (1703272, '2009', '07743777000195', '2009-10-24', 'Nota Fiscal', '10', 'AUTO EIXO 208 NORTE LTDA', '119639', '3107', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 160.099999999999994, 0, 160.099999999999994, 141535);
INSERT INTO despesas VALUES (1685813, '2009', '08202116000115', '2009-09-30', 'Nota Fiscal', '9', 'AUTO POSTO AEROPORTO', '583922', '3090', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141535);
INSERT INTO despesas VALUES (1610376, '2009', '08202116000115', '2009-06-17', 'Nota Fiscal', '6', 'AUTO POSTO AEROPORTO LTDA', '522701', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1630681, '2009', '08202116000115', '2009-07-16', 'Nota Fiscal', '7', 'AUTO POSTO AEROPORTO LTDA', '539432', '2988', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141535);
INSERT INTO despesas VALUES (1650461, '2009', '08202116000115', '2009-08-13', 'Nota Fiscal', '8', 'AUTO POSTO AEROPORTO LTDA', '555693', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1695089, '2009', '08202116000115', '2009-10-14', 'Nota Fiscal', '10', 'AUTO POSTO AEROPORTO LTDA', '591370', '3095', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1650466, '2009', '00000042001013', '2009-08-14', 'Nota Fiscal', '8', 'AUTO POSTO GASOL LTDA', '158943', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 86.5, 0, 86.5, 141535);
INSERT INTO despesas VALUES (1612662, '2009', '02316635000128', '2009-06-23', 'Nota Fiscal', '6', 'AUTO POSTO JARDIM BRASILIA LTDA', '326748', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1601632, '2009', '05256794000172', '2009-06-03', 'Nota Fiscal', '6', 'AUTO POSTO KJ', '087168', '2930', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 40, 0, 40, 141535);
INSERT INTO despesas VALUES (1671231, '2009', '01968210000130', '2009-09-05', 'Nota Fiscal', '9', 'AUTO POSTO SANTA MARIA LTDA', '000922', '3065', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 79, 0, 79, 141535);
INSERT INTO despesas VALUES (1697909, '2009', '37128428000124', '2009-10-20', 'Nota Fiscal', '10', 'AUTO SHOPPING SOBRADINHO DER. DE PETROLEO', '034231', '3099', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141535);
INSERT INTO despesas VALUES (1720399, '2009', '37128428000124', '2009-11-11', 'Nota Fiscal', '11', 'AUTO SHOPPING SOBRADINHO DERIVADOS DE PETROLEO', '031296', '3128', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 141535);
INSERT INTO despesas VALUES (1720405, '2009', '37128428000124', '2009-11-11', 'Nota Fiscal', '11', 'AUTO SHOPPING SOBRADINHO DERIVADOS DE PETROLEO', '031306', '3128', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 239.02000000000001, 0, 239.02000000000001, 141535);
INSERT INTO despesas VALUES (1724693, '2009', '37128428000124', '2009-11-22', 'Nota Fiscal', '11', 'AUTO SHOPPING SOBRADINHO DERIVADOS DE PETROLEO', '037037', '3135', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 124.579999999999998, 0, 124.579999999999998, 141535);
INSERT INTO despesas VALUES (1724692, '2009', '37128428000124', '2009-11-22', 'Nota Fiscal', '11', 'AUTO SHOPPING SOBRADINHO DERIVADOS DE PETROLEO', '037038', '3135', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 152.909999999999997, 0, 152.909999999999997, 141535);
INSERT INTO despesas VALUES (1678185, '2009', '37128428000124', '2009-09-23', 'Nota Fiscal', '9', 'AUTO SHOPPING SOBRADINHO DERIVADOS DE PETROLEO LTD', '007963', '3073', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1678187, '2009', '37128428000124', '2009-09-23', 'Nota Fiscal', '9', 'AUTO SHOPPING SOBRADINHO DERIVADOS DE PETROLEO LTD', '007964', '3073', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 148.009999999999991, 0, 148.009999999999991, 141535);
INSERT INTO despesas VALUES (1670265, '2009', '37128428000124', '2009-09-13', 'Nota Fiscal', '9', 'AUTO SHOPPING SOBRADINHO DERIVEDOS DE PETROLEO', '025051', '3065', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141535);
INSERT INTO despesas VALUES (1678244, '2009', '00373589000416', '2009-09-22', 'Nota Fiscal', '9', 'CAL COMBUSTÍVEIS AUTOMOTIVEIS LTDA', '059405', '3073', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1614939, '2009', '00373589000416', '2009-06-29', 'Nota Fiscal', '6', 'CAL COMBUSTÍVEIS AUTOMOTIVOS', '052482', '2949', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1681807, '2009', '00373589000416', '2009-09-29', 'Nota Fiscal', '9', 'CAL COMBUSTÍVEIS AUTOMOTIVOS LTDA', '059998', '3090', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1587702, '2009', '00373589000505', '2009-05-14', 'Nota Fiscal', '5', 'CAL COMBUSTIVEIS AUTOMOTIVOS LTDA', '012225', '2915', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1598278, '2009', '00373589000416', '2009-06-02', 'Nota Fiscal', '6', 'CAL COMBUSTIVEIS AUTOMOVEIS LTDA', '050241', '2929', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1651140, '2009', '35304542000213', '2009-08-14', 'Nota Fiscal', '8', 'CIRNE ONEUS COMERCIO E SERVIÇOS LTDA', '092648', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 82.8700000000000045, 0, 82.8700000000000045, 141535);
INSERT INTO despesas VALUES (1659412, '2009', '00715375000138', '2009-08-26', 'Nota Fiscal', '8', 'COMAL COMBUSTIVEIS AUTOMOTIVOS LTDA', '001902', '3044', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141535);
INSERT INTO despesas VALUES (1685815, '2009', '03202654000277', '2009-09-29', 'Nota Fiscal', '9', 'COMERCIAL DE PETROLEO CABUGI ', '004023', '3090', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 118, 0, 118, 141535);
INSERT INTO despesas VALUES (1651143, '2009', '10216945000107', '2009-08-16', 'Nota Fiscal', '8', 'COMVALLEY COMERCIAL DE COMBUSTIVEIS LTDA', '014421', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 110, 0, 110, 141535);
INSERT INTO despesas VALUES (1714589, '2009', '00012211000144', '2009-11-09', 'Nota Fiscal', '11', 'DRIVE CAR', '137832', '3123', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 200, 0, 200, 141535);
INSERT INTO despesas VALUES (1711040, '2009', '00012211000144', '2009-11-03', 'Nota Fiscal', '11', 'DRIVE CAR TRANSPORTES E COMBUSTIVEIS', '007445', '3116', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1736543, '2009', '00012211000144', '2009-11-30', 'Nota Fiscal', '11', 'DRIVE CAR TRANSPORTES E COMBUSTIVEIS', '008950', '3152', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1583019, '2009', '00012211000144', '2009-05-06', 'Nota Fiscal', '5', 'DRIVE CAR TRANSPORTES E COMBUSTIVEIS LTDA', '066601', '2909', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141535);
INSERT INTO despesas VALUES (1612988, '2009', '00012211000144', '2009-06-23', 'Nota Fiscal', '6', 'DRIVE CAR TRANSPORTES E COMBUSTIVEIS LTDA', '134907', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1616921, '2009', '00012211000144', '2009-07-01', 'Nota Fiscal', '7', 'DRIVE CAR TRANSPORTES E COMBUSTÌVEIS LTDA', '135074', '2953', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1706715, '2009', '00012211000144', '2009-10-28', 'Nota Fiscal', '10', 'DRIVE CAR TRANSPORTES E COMBUSTIVEIS LTDA', '137605', '3111', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1736547, '2009', '00012211000144', '2009-12-07', 'Nota Fiscal', '12', 'DRIVE CAR TRANSPORTES E COMBUSTÍVEIS LTDA', '138458', '3152', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1562149, '2009', '00012211000144', '2009-04-02', 'Nota Fiscal', '4', 'DRIVER CAR - TRANSPORTES E COMBUSTÍVEIS LTDA', '133122', '2884', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1651121, '2009', '03255891000115', '2009-08-15', 'Nota Fiscal', '8', 'FAMA COMERCIO E SERVIÇO LTDA', '069608', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1588719, '2009', '08437352000110', '2009-05-15', 'Nota Fiscal', '5', 'FRANCISCO BEZERRA DE MELO', '026540', '2918', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 127.159999999999997, 0, 127.159999999999997, 141535);
INSERT INTO despesas VALUES (1697912, '2009', '08884038000186', '2009-10-19', 'Nota Fiscal', '10', 'FRATELLI POSTO DE COMBUSTIVEIS LTDA', '068673', '3099', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1620103, '2009', '00306597001098', '2009-07-06', 'Nota Fiscal', '7', 'GASOL COMBUSTÍVEIS', '61258', '2953', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1614448, '2009', '00603738000658', '2009-06-27', 'Nota Fiscal', '6', 'GASOL COMBUSTIVEIS', '026990', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1614449, '2009', '00603738000658', '2009-06-27', 'Nota Fiscal', '6', 'GASOL COMBUSTIVEIS', '026993', '2947', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 146.759999999999991, 0, 146.759999999999991, 141535);
INSERT INTO despesas VALUES (1632511, '2009', '00603738000658', '2009-07-19', 'Nota Fiscal', '7', 'GASOL COMBUSTIVEIS AUTOMOTIVOS LTDA', '027866', '2994', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 154, 0, 154, 141535);
INSERT INTO despesas VALUES (1654291, '2009', '00603738000658', '2009-08-22', 'Nota Fiscal', '8', 'GASOL COMBUSTIVEIS AUTOMOTIVOS LTDA', '029234', '3036', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 140, 0, 140, 141535);
INSERT INTO despesas VALUES (1670269, '2009', '00603738000658', '2009-09-12', 'Nota Fiscal', '9', 'GASOL COMBUSTIVEIS AUTOMOTIVOS LTDA', '030123', '3065', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 141535);
INSERT INTO despesas VALUES (1730226, '2009', '00603738000658', '2009-11-29', 'Nota Fiscal', '11', 'GASOL COMBUSTIVEIS AUTOMOTIVOS LTDA', '033034', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 136, 0, 136, 141535);
INSERT INTO despesas VALUES (1606951, '2009', '00603738000658', '2009-06-13', 'Nota Fiscal', '6', 'GASOL COMBUSTIVEIS AUTOMOVEIS LTDA', '026510', '2938', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 60, 0, 60, 141535);
INSERT INTO despesas VALUES (1606965, '2009', '07006283000209', '2009-05-18', 'Nota Fiscal', '5', 'GEL PETROLEO LTDA', '357898', '2938', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 135.120000000000005, 0, 135.120000000000005, 141535);
INSERT INTO despesas VALUES (1650465, '2009', '04499302000107', '2009-08-15', 'Nota Fiscal', '8', 'HOR PETRO AUTO POSTO LTDA', '095347', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 79.9899999999999949, 0, 79.9899999999999949, 141535);
INSERT INTO despesas VALUES (1575008, '2009', '08510133001353', '2009-04-24', 'Nota Fiscal', '4', 'JM BEZERRA & CIA LTDA', '013385', '2900', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 144.960000000000008, 0, 144.960000000000008, 141535);
INSERT INTO despesas VALUES (1703338, '2009', '08328395000400', '2009-10-18', 'Nota Fiscal', '10', 'JOAQUIM ALVES FLOR & CIA LTDA', '325037', '3107', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 141535);
INSERT INTO despesas VALUES (1567043, '2009', '08328395000168', '2009-03-06', 'Nota Fiscal', '3', 'JOAQUIM ALVES FLOR E CIA LTDA', '220510', '2893', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 122.5, 0, 122.5, 141535);
INSERT INTO despesas VALUES (1567030, '2009', '03315118000792', '2009-04-11', 'Nota Fiscal', '4', 'JOSÉ MENDES DA SILVA POSTO DE GASOLINA', '003665', '2893', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 40, 0, 40, 141535);
INSERT INTO despesas VALUES (1611073, '2009', '07984845000108', '2009-06-20', 'Nota Fiscal', '6', 'L A F COMERCIO DE COMBUSTIVEIS LTDA', '196736', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 142.069999999999993, 0, 142.069999999999993, 141535);
INSERT INTO despesas VALUES (1651131, '2009', '08693517000115', '2009-08-07', 'Nota Fiscal', '8', 'LUIZ FLOR & FILHOS LTDA', '052503', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 20.0100000000000016, 0, 20.0100000000000016, 141535);
INSERT INTO despesas VALUES (1651127, '2009', '08693517000115', '2009-08-03', 'Nota Fiscal', '8', 'LUIZ FLOR & FILHOS LTDA', '275016', '3027', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 20, 0, 20, 141535);
INSERT INTO despesas VALUES (1588691, '2009', '08693517000204', '2009-05-03', 'Nota Fiscal', '5', 'LUIZ FLOR & FILHOS LTDA', '131222', '2918', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 123.870000000000005, 0, 123.870000000000005, 141535);
INSERT INTO despesas VALUES (1685818, '2009', '08693517000204', '2009-09-26', 'Nota Fiscal', '9', 'LUIZ FLOR & FILHOS LTDA', '161620', '3090', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 80, 0, 80, 141535);
INSERT INTO despesas VALUES (1588705, '2009', '08345698000199', '2009-05-15', 'Nota Fiscal', '5', 'M B COMBUSTIVEIS', '041590', '2918', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 157.639999999999986, 15, 142.639999999999986, 141535);
INSERT INTO despesas VALUES (1765070, '2009', '08397366000743', '2009-12-09', 'Nota Fiscal', '12', 'MARPAS', '097118', '3213', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 137.539999999999992, 0, 137.539999999999992, 141535);
INSERT INTO despesas VALUES (1714883, '2009', '08345698000199', '2009-11-06', 'Nota Fiscal', '11', 'MB COM. DERIVADOS DE PETROLEO', '137007', '3123', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100.019999999999996, 0, 100.019999999999996, 141535);
INSERT INTO despesas VALUES (1726102, '2009', '08345698000199', '2009-11-12', 'Nota Fiscal', '11', 'MB COM. E DERIVADOS DE PETROLEO LTDA', '059649', '3132', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 141535);
INSERT INTO despesas VALUES (1707958, '2009', '08345698000199', '2009-11-02', 'Nota Fiscal', '11', 'MB COMB. DERIVADOS DE PETROLEO', '135158', '3115', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 130, 0, 130, 141535);
INSERT INTO despesas VALUES (1726116, '2009', '08345698000199', '2009-11-23', 'Nota Fiscal', '11', 'MB COMB. DERIVADOS DE PETROLEO', '145315', '3132', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50.0399999999999991, 0, 50.0399999999999991, 141535);
INSERT INTO despesas VALUES (1726110, '2009', '08345698000199', '2009-11-07', 'Nota Fiscal', '11', 'MB COMB. DERIVADOS DE PETROLEO LTDA', '059403', '3132', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50.0200000000000031, 0, 50.0200000000000031, 141535);
INSERT INTO despesas VALUES (1635354, '2009', '08345698000199', '2009-07-31', 'Nota Fiscal', '7', 'MB COMB. E DERIVADOS DE PETROLEO', '050132', '3004', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 146, 0, 146, 141535);
INSERT INTO despesas VALUES (1588715, '2009', '08345698000199', '2009-05-08', 'Nota Fiscal', '5', 'MB COMBUSTIVEIS', '040574', '2918', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 143, 0, 143, 141535);
INSERT INTO despesas VALUES (1611449, '2009', '08345698000199', '2009-05-25', 'Nota Fiscal', '5', 'MB COMBUSTIVEIS', '042939', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 134.210000000000008, 0, 134.210000000000008, 141535);
INSERT INTO despesas VALUES (1611090, '2009', '08345698000199', '2009-05-27', 'Nota Fiscal', '5', 'MB COMBUSTIVEIS', '043211', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100.010000000000005, 0, 100.010000000000005, 141535);
INSERT INTO despesas VALUES (1611106, '2009', '08345698000199', '2009-06-17', 'Nota Fiscal', '6', 'MB COMBUSTIVEIS', '045290', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 116.049999999999997, 0, 116.049999999999997, 141535);
INSERT INTO despesas VALUES (1611445, '2009', '08345698000199', '2009-06-22', 'Nota Fiscal', '6', 'MB COMBUSTIVEIS', '045727', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 122.319999999999993, 0, 122.319999999999993, 141535);
INSERT INTO despesas VALUES (1611450, '2009', '08345698000199', '2009-06-03', 'Nota Fiscal', '6', 'MB COMBUSTIVEIS', '083852', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 122.739999999999995, 0, 122.739999999999995, 141535);
INSERT INTO despesas VALUES (1611078, '2009', '08345698000199', '2009-05-31', 'Nota Fiscal', '5', 'MB COMBUSTIVES', '082678', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 135.22999999999999, 0, 135.22999999999999, 141535);
INSERT INTO despesas VALUES (1611082, '2009', '08345698000199', '2009-06-15', 'Nota Fiscal', '6', 'MB COMBUSTIVES', '086925', '2943', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 120.890000000000001, 0, 120.890000000000001, 141535);
INSERT INTO despesas VALUES (1730219, '2009', '08345698000199', '2009-11-30', 'Nota Fiscal', '11', 'MBCOM. DERIVADOS DE PETROLEO LTDA', '060238', '3140', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50.0200000000000031, 0, 50.0200000000000031, 141535);
INSERT INTO despesas VALUES (5847680, '2015', '17338795000145', '2015-11-05', 'Recibos/Outros', '10', 'ALI ADMINISTRAÇÃO DE IMOVEIS LTDA', '10/2015', '5235', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 1800, 178952);
INSERT INTO despesas VALUES (5869881, '2015', '17338795000145', '2015-12-05', 'Recibos/Outros', '11', 'ALI ADMINISTRAÇÃO DE IMOVEIS LTDA', 'S/N', '5256', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 1800, 178952);
INSERT INTO despesas VALUES (5877322, '2015', '17338795000145', '2015-12-15', 'Recibos/Outros', '12', 'ALI ADMINISTRAÇÃO DE IMOVEIS LTDA', 'S/N', '5276', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 1800, 178952);
INSERT INTO despesas VALUES (5820178, '2015', '17338795000145', '2015-10-05', 'Recibos/Outros', '9', 'ALI ADMINISTRAÇÃO DE IMOVEIS LTDA', 'SN', '5201', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 1800, 178952);
INSERT INTO despesas VALUES (5708258, '2015', '02952192000161', '2015-06-01', 'Nota Fiscal', '5', 'CABOTELECOM', '13443', '5059', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 73.8599999999999994, 0, 73.8599999999999994, 178952);
INSERT INTO despesas VALUES (5791409, '2015', '02952192000161', '2015-09-01', 'Nota Fiscal', '8', 'CABOTELECOM', '13902', '5152', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 155.129999999999995, 0, 155.129999999999995, 178952);
INSERT INTO despesas VALUES (5847726, '2015', '02952192000161', '2015-11-01', 'Nota Fiscal', '10', 'CABOTELECOM', '16776', '5233', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 160.550000000000011, 0, 160.550000000000011, 178952);
INSERT INTO despesas VALUES (5820113, '2015', '02952192000161', '2015-10-01', 'Nota Fiscal', '9', 'CABOTELECOM', '17051', '5201', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 158.909999999999997, 0, 158.909999999999997, 178952);
INSERT INTO despesas VALUES (5904175, '2015', '02952192000161', '2016-01-01', 'Nota Fiscal', '12', 'CABOTELECOM', '21730', '5325', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 163.969999999999999, 0, 163.969999999999999, 178952);
INSERT INTO despesas VALUES (5874109, '2015', '02952192000161', '2015-12-01', 'Nota Fiscal', '11', 'CABOTELECOM', '21740', '5277', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 161.379999999999995, 0, 161.379999999999995, 178952);
INSERT INTO despesas VALUES (5904234, '2015', '40432544007826', '2015-12-24', 'Nota Fiscal', '12', 'CLARO S/A', '00024417', '5325', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 68.5, 0, 68.5, 178952);
INSERT INTO despesas VALUES (5725331, '2015', '12132854000100', '2015-06-18', 'Nota Fiscal', '6', 'Comércio de Artigos de Papelaria LTDA', '01920', '5078', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 645, 0, 645, 178952);
INSERT INTO despesas VALUES (5739048, '2015', '12132854000100', '2015-07-01', 'Nota Fiscal', '7', 'COMÉRCIO DE ARTIGOS DE PAPELARIA LTDA-ME', '01938', '5099', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 315, 0, 315, 178952);
INSERT INTO despesas VALUES (5791385, '2015', '08324196000181', '2015-08-14', 'Nota Fiscal', '8', 'COSERN', '000622640', '5152', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 153.960000000000008, 3.35000000000000009, 150.610000000000014, 178952);
INSERT INTO despesas VALUES (5874104, '2015', '08324196000181', '2015-11-13', 'Nota Fiscal', '11', 'COSERN', '000633995', '5277', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 154.780000000000001, 0, 154.780000000000001, 178952);
INSERT INTO despesas VALUES (5904212, '2015', '08324196000181', '2015-12-15', 'Nota Fiscal', '12', 'COSERN', '000646982', '5325', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 217.580000000000013, 0, 217.580000000000013, 178952);
INSERT INTO despesas VALUES (5758244, '2015', '08324196000181', '2015-07-15', 'Nota Fiscal', '7', 'COSERN', '000656887', '5119', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 158.009999999999991, 3.68999999999999995, 154.319999999999993, 178952);
INSERT INTO despesas VALUES (5847689, '2015', '08324196000181', '2015-10-15', 'Nota Fiscal', '10', 'COSERN', '000664675', '5233', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 158.319999999999993, 0, 158.319999999999993, 178952);
INSERT INTO despesas VALUES (5820125, '2015', '08324196000181', '2015-09-15', 'Nota Fiscal', '9', 'COSERN', '000667515', '5201', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 163.919999999999987, 3.31000000000000005, 160.610000000000014, 178952);
INSERT INTO despesas VALUES (5758177, '2015', '08324196000181', '2015-06-16', 'Nota Fiscal', '6', 'COSERN', '000791045', '5119', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 181.780000000000001, 0, 181.780000000000001, 178952);
INSERT INTO despesas VALUES (5675555, '2015', '22254012000185', '2015-05-04', 'Recibos/Outros', '5', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', '1057', '5030', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 350, 31.5300000000000011, 318.470000000000027, 178952);
INSERT INTO despesas VALUES (5758257, '2015', '22254012000185', '2015-07-24', 'Recibos/Outros', '8', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', '1199', '5119', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 329.920000000000016, 30.0700000000000003, 299.850000000000023, 178952);
INSERT INTO despesas VALUES (5791403, '2015', '22254012000185', '2015-08-18', 'Recibos/Outros', '9', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', '1309', '5152', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 338.899999999999977, 30.0700000000000003, 308.829999999999984, 178952);
INSERT INTO despesas VALUES (5847736, '2015', '22254012000185', '2015-10-14', 'Recibos/Outros', '11', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', '1401', '5234', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 338.899999999999977, 30.0700000000000003, 308.829999999999984, 178952);
INSERT INTO despesas VALUES (5874115, '2015', '22254012000185', '2015-11-16', 'Recibos/Outros', '12', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', '1446', '5279', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 338.899999999999977, 30.0700000000000003, 308.829999999999984, 178952);
INSERT INTO despesas VALUES (5708255, '2015', '22254012000185', '2015-06-05', 'Recibos/Outros', '6', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', 'SN', '5059', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 346.829999999999984, 31.5300000000000011, 315.300000000000011, 178952);
INSERT INTO despesas VALUES (5758233, '2015', '22254012000185', '2015-06-26', 'Recibos/Outros', '7', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', 'SN', '5119', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 347.879999999999995, 30.9100000000000001, 316.970000000000027, 178952);
INSERT INTO despesas VALUES (5820205, '2015', '22254012000185', '2015-09-15', 'Recibos/Outros', '10', 'EDIFICIO EMPRESARIAL DELMIRO GOUVEIA', 'SN', '5201', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 338.899999999999977, 30.0700000000000003, 308.829999999999984, 178952);
INSERT INTO despesas VALUES (5675606, '2015', '04958358000263', '2015-05-04', 'Nota Fiscal', '5', 'LIVRARIA CÂMARA CASCUDO', '55040', '5030', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 367.560000000000002, 43.25, 324.310000000000002, 178952);
INSERT INTO despesas VALUES (5791435, '2015', '04958358000263', '2015-09-01', 'Nota Fiscal', '9', 'LIVRARIA CÂMARA CASCUDO', '58628', '5152', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 188.789999999999992, 0, 188.789999999999992, 178952);
INSERT INTO despesas VALUES (5847778, '2015', '04958358000263', '2015-10-27', 'Nota Fiscal', '10', 'LIVRARIA CÂMARA CASCUDO', '60124', '5233', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 49.4799999999999969, 0, 49.4799999999999969, 178952);
INSERT INTO despesas VALUES (5847788, '2015', '04958358000263', '2015-11-06', 'Nota Fiscal', '11', 'LIVRARIA CÂMARA CASCUDO', '60504', '5233', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 68.8700000000000045, 0, 68.8700000000000045, 178952);
INSERT INTO despesas VALUES (5732671, '2015', '11982113000741', '2015-06-08', 'Nota Fiscal', '6', 'MIRANDA COMPUTAÇÃO E COMÉRCIO LTDA', '239631', '5094', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 218.409999999999997, 0, 218.409999999999997, 178952);
INSERT INTO despesas VALUES (5823970, '2015', '11982113000741', '2015-10-14', 'Nota Fiscal', '10', 'MIRANDA COMPUTAÇÃO E COMÉRCIO LTDA', '253799', '5201', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 237.400000000000006, 0, 237.400000000000006, 178952);
INSERT INTO despesas VALUES (5796536, '2015', '17338795000145', '2015-09-05', 'Recibos/Outros', '8', 'SJ NATAL - ADMINISTRAÇÃO DE IMOVEIS LTDA', '08/2015', '5161', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 0, 178952);
INSERT INTO despesas VALUES (5708246, '2015', '17338795000145', '2015-06-05', 'Recibos/Outros', '5', 'SJ NATAL - ADMINISTRAÇÃO DE IMOVEIS LTDA', 'S/N', '5059', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 1800, 178952);
INSERT INTO despesas VALUES (5737040, '2015', '17338795000145', '2015-07-13', 'Recibos/Outros', '6', 'SJ NATAL - ADMINISTRAÇÃO DE IMOVEIS LTDA', 's/n', '5096', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 1800, 178952);
INSERT INTO despesas VALUES (5675595, '2015', '17338795000145', '2015-05-04', 'Recibos/Outros', '4', 'SJ NATAL - ADMINISTRAÇÃO DE IMOVEIS LTDA', 'SN', '5026', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 0, 178952);
INSERT INTO despesas VALUES (5766453, '2015', '17338795000145', '2015-08-05', 'Recibos/Outros', '7', 'SJ NATAL - ADMINISTRAÇÃO DE IMOVEIS LTDA', 'SN', '5125', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1800, 0, 1800, 178952);
INSERT INTO despesas VALUES (5670403, '2015', '12132854000100', '2015-04-29', 'Nota Fiscal', '4', 'WMS Comércio de Artigos de Papelaria LTDA', '01823', '5021', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 688.5, 0, 688.5, 178952);
INSERT INTO despesas VALUES (5699647, '2015', '12132854000100', '2015-05-07', 'Nota Fiscal', '5', 'WMS Comércio de Artigos de Papelaria LTDA', '01838', '5049', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 673.100000000000023, 0, 673.100000000000023, 178952);
INSERT INTO despesas VALUES (5609388, '2015', '12132854000100', '2015-02-09', 'Nota Fiscal', '2', 'WMS Comércio de Artigos de Papelaria LTDA', '1614', '4946', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1034.5, 0, 1034.5, 178952);
INSERT INTO despesas VALUES (5631579, '2015', '12132854000100', '2015-03-18', 'Nota Fiscal', '3', 'WMS Comércio de Artigos de Papelaria LTDA', '1752', '4968', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 597.5, 0, 597.5, 178952);
INSERT INTO despesas VALUES (5801140, '2015', '12132854000100', '2015-09-24', 'Nota Fiscal', '9', 'WMS COMÉRCIO DE ARTIGOS DE PAPELARIA LTDA-ME', '02081', '5172', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 543.399999999999977, 0, 543.399999999999977, 178952);
INSERT INTO despesas VALUES (5862934, '2015', '12132854000100', '2015-12-01', 'Nota Fiscal', '12', 'WMS COMÉRCIO DE ARTIGOS DE PAPELARIA LTDA-ME', '02215', '5254', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 295, 0, 295, 178952);
INSERT INTO despesas VALUES (5791356, '2015', '05299796000149', '2015-08-28', 'Nota Fiscal', '8', 'AUTO POSTO ALMENARA LTDA.', '018416', '5152', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 174.580000000000013, 0, 174.580000000000013, 178952);
INSERT INTO despesas VALUES (5818222, '2015', '05299796000149', '2015-10-07', 'Nota Fiscal', '10', 'AUTO POSTO ALMENARA LTDA.', '032765', '5190', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178952);
INSERT INTO despesas VALUES (5837970, '2015', '05299796000149', '2015-10-15', 'Nota Fiscal', '10', 'AUTO POSTO ALMENARA LTDA.', '035926', '5216', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 200, 0, 200, 178952);
INSERT INTO despesas VALUES (5699835, '2015', '05299796000149', '2015-05-22', 'Nota Fiscal', '5', 'AUTO POSTO ALMENARA LTDA.', '635230', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178952);
INSERT INTO despesas VALUES (5720031, '2015', '05299796000149', '2015-06-15', 'Nota Fiscal', '6', 'AUTO POSTO ALMENARA LTDA.', '654412', '5072', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178952);
INSERT INTO despesas VALUES (5801151, '2015', '05299796000149', '2015-09-09', 'Nota Fiscal', '9', 'AUTO POSTO ALMENARA LTDA.', '693331', '5172', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 190.419999999999987, 0, 190.419999999999987, 178952);
INSERT INTO despesas VALUES (5801146, '2015', '05299796000149', '2015-09-17', 'Nota Fiscal', '9', 'AUTO POSTO ALMENARA LTDA.', '696224', '5172', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150.009999999999991, 0, 150.009999999999991, 178952);
INSERT INTO despesas VALUES (5837980, '2015', '05299796000149', '2015-10-27', 'Nota Fiscal', '10', 'AUTO POSTO ALMENARA LTDA.', '711116', '5216', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 200, 0, 200, 178952);
INSERT INTO despesas VALUES (5877539, '2015', '05299796000149', '2015-12-03', 'Nota Fiscal', '12', 'AUTO POSTO ALMENARA LTDA.', '723794', '5277', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 200, 0, 200, 178952);
INSERT INTO despesas VALUES (5864283, '2015', '09103975000110', '2015-11-29', 'Nota Fiscal', '11', 'AUTO POSTO ORIGINAL BRASILIA DERIVADOS DE PETROLEO LTDA - ME', '129909', '5253', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 187.759999999999991, 0, 0, 178952);
INSERT INTO despesas VALUES (5874147, '2015', '09103975000110', '2015-12-11', 'Nota Fiscal', '12', 'AUTO POSTO ORIGINAL BRASILIA DERIVADOS DE PETROLEO LTDA - ME', '132181', '5277', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 187.490000000000009, 0, 187.490000000000009, 178952);
INSERT INTO despesas VALUES (5609330, '2015', '09103975000110', '2015-02-12', 'Nota Fiscal', '2', 'AUTO POSTO ORIGINAL BSB DER PETROLEO LTDA', '079044', '4944', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 157.669999999999987, 0, 157.669999999999987, 178952);
INSERT INTO despesas VALUES (5625181, '2015', '09103975000110', '2015-03-08', 'Nota Fiscal', '3', 'AUTO POSTO ORIGINAL BSB DER PETROLEO LTDA', '084215', '4959', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 179.469999999999999, 0, 179.469999999999999, 178952);
INSERT INTO despesas VALUES (5636166, '2015', '09103975000110', '2015-03-24', 'Nota Fiscal', '3', 'AUTO POSTO ORIGINAL BSB DER PETROLEO LTDA', '088077', '4973', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 158.5, 0, 158.5, 178952);
INSERT INTO despesas VALUES (5652032, '2015', '09103975000110', '2015-04-09', 'Nota Fiscal', '4', 'AUTO POSTO ORIGINAL BSB DER PETROLEO LTDA', '090664', '4995', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 167.050000000000011, 0, 167.050000000000011, 178952);
INSERT INTO despesas VALUES (5780206, '2015', '09103975000110', '2015-09-02', 'Nota Fiscal', '9', 'AUTO POSTO ORIGINAL BSB DER PETROLEO LTDA', '117566', '5137', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 170.25, 0, 170.25, 178952);
INSERT INTO despesas VALUES (5847743, '2015', '09103975000110', '2015-11-12', 'Nota Fiscal', '11', 'AUTO POSTO ORIGINAL BSB DER PETROLEO LTDA', '127632', '5233', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 174.97999999999999, 0, 174.97999999999999, 178952);
INSERT INTO despesas VALUES (5837975, '2015', '09103975000110', '2015-10-22', 'Nota Fiscal', '10', 'AUTO POSTO ORIGINAL BSB DER PETROLEO LTDA', '313671', '5216', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 180.930000000000007, 0, 180.930000000000007, 178952);
INSERT INTO despesas VALUES (5738557, '2015', '05564770000261', '2015-07-10', 'Nota Fiscal', '7', 'CARAU COMBUSTÍVEL LTDA', '1081813', '5099', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 2987.55000000000018, 0, 2987.55000000000018, 178952);
INSERT INTO despesas VALUES (5780147, '2015', '05564770000261', '2015-08-14', 'Nota Fiscal', '8', 'CARAU COMBUSTÍVEL LTDA', '1081882', '5137', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 1457.93000000000006, 0, 1457.93000000000006, 178952);
INSERT INTO despesas VALUES (5796516, '2015', '05564770000261', '2015-09-15', 'Nota Fiscal', '9', 'CARAU COMBUSTÍVEL LTDA', '1081944', '5165', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 2970.03999999999996, 0, 2970.03999999999996, 178952);
INSERT INTO despesas VALUES (5820144, '2015', '05564770000261', '2015-10-13', 'Nota Fiscal', '10', 'CARAU COMBUSTÍVEL LTDA', '1081997', '5201', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 2998.63999999999987, 42, 2956.63999999999987, 178952);
INSERT INTO despesas VALUES (5855552, '2015', '05564770000261', '2015-11-19', 'Nota Fiscal', '11', 'CARAU COMBUSTÍVEL LTDA', '1082070', '5242', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 2872.59999999999991, 0, 2872.59999999999991, 178952);
INSERT INTO despesas VALUES (5878643, '2015', '05564770000261', '2015-12-16', 'Nota Fiscal', '12', 'CARAU COMBUSTÍVEL LTDA', '1082131', '5277', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 3612.65999999999985, 0, 3612.65999999999985, 178952);
INSERT INTO despesas VALUES (5780140, '2015', '05564770000261', '2015-08-14', 'Nota Fiscal', '8', 'CARAU COMBUSTÍVEL LTDA', '10881', '5137', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 1437.27999999999997, 0, 1437.27999999999997, 178952);
INSERT INTO despesas VALUES (5758292, '2015', '00306597007290', '2015-08-10', 'Nota Fiscal', '8', 'CASCOL COMBUSTIVEIS LTDA', '020073', '5119', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 171.669999999999987, 0, 171.669999999999987, 178952);
INSERT INTO despesas VALUES (5855563, '2015', '00306597007290', '2015-11-20', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS LTDA', '023488', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 186.77000000000001, 0, 186.77000000000001, 178952);
INSERT INTO despesas VALUES (5720036, '2015', '00306597007290', '2015-06-22', 'Nota Fiscal', '6', 'Cascol Combustíveis Para Veículos  Ltda', '018720', '5072', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 174.550000000000011, 0, 174.550000000000011, 178952);
INSERT INTO despesas VALUES (5732623, '2015', '00306597007290', '2015-07-03', 'Nota Fiscal', '7', 'Cascol Combustíveis Para Veículos  Ltda', '019041', '5091', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 170.169999999999987, 0, 170.169999999999987, 178952);
INSERT INTO despesas VALUES (5699816, '2015', '00306597000601', '2015-06-02', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '013409', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 161.939999999999998, 0, 161.939999999999998, 178952);
INSERT INTO despesas VALUES (5752036, '2015', '00306597000601', '2015-07-22', 'Nota Fiscal', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '014465', '5118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 173.039999999999992, 0, 173.039999999999992, 178952);
INSERT INTO despesas VALUES (5796524, '2015', '00306597000601', '2015-09-21', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '015524', '5157', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 165.909999999999997, 0, 165.909999999999997, 178952);
INSERT INTO despesas VALUES (5679548, '2015', '00306597002906', '2015-05-11', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '006869', '5032', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 171.689999999999998, 0, 171.689999999999998, 178952);
INSERT INTO despesas VALUES (5631586, '2015', '07821726000134', '2015-03-17', 'Nota Fiscal', '3', 'DFM - Derivados de Petróleo Ltda', '070153', '4966', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178952);
INSERT INTO despesas VALUES (5601101, '2015', '07821726000134', '2015-02-03', 'Nota Fiscal', '2', 'DFM - Derivados de Petróleo Ltda', '39525', '4959', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 30, 0, 30, 178952);
INSERT INTO despesas VALUES (5720042, '2015', '08202116000115', '2015-05-26', 'Nota Fiscal', '5', 'JK COMBUSTÍVEIS', '449239', '5072', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178952);
INSERT INTO despesas VALUES (5738559, '2015', '02072286000650', '2015-07-14', 'Nota Fiscal', '7', 'PETROIL COMBUSTIVEIS LTDA', '278532', '5098', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 200, 0, 200, 178952);
INSERT INTO despesas VALUES (5772717, '2015', '02072286000650', '2015-08-22', 'Nota Fiscal', '8', 'PETROIL COMBUSTIVEIS LTDA', '295035', '5131', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 159.590000000000003, 0, 159.590000000000003, 178952);
INSERT INTO despesas VALUES (5699827, '2015', '00042044000184', '2015-05-23', 'Nota Fiscal', '5', 'POLAR DERIVADOS DE PETRÓLEO LTDA', '193808', '5049', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 165.879999999999995, 0, 165.879999999999995, 178952);
INSERT INTO despesas VALUES (5670402, '2015', '05158335000156', '2015-04-30', 'Nota Fiscal', '4', 'POSTO 109 SUL DERIVADOS DE PETRÓLEO LTDA', '036836', '5021', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 170.180000000000007, 0, 170.180000000000007, 178952);
INSERT INTO despesas VALUES (5720094, '2015', '04473193000159', '2015-05-09', 'Nota Fiscal', '5', 'POSTO DA TORRE EIRELI EPP', '013450', '5072', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 164.689999999999998, 0, 164.689999999999998, 178952);
INSERT INTO despesas VALUES (5732609, '2015', '04473193000159', '2015-07-02', 'Nota Fiscal', '7', 'POSTO DA TORRE EIRELI EPP', '025861', '5091', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 197.099999999999994, 0, 197.099999999999994, 178952);
INSERT INTO despesas VALUES (5761952, '2015', '04473193000159', '2015-08-13', 'Nota Fiscal', '8', 'POSTO DA TORRE EIRELI EPP', '048350', '5125', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 190, 0, 190, 178952);
INSERT INTO despesas VALUES (5864278, '2015', '04473193000159', '2015-11-23', 'Nota Fiscal', '11', 'POSTO DA TORRE EIRELI EPP', '064329', '5253', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 200.02000000000001, 0, 0, 178952);
INSERT INTO despesas VALUES (5804759, '2015', '04473193000159', '2015-09-30', 'Nota Fiscal', '9', 'POSTO DA TORRE EIRELI EPP', '069781', '5172', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 200, 0, 200, 178952);
INSERT INTO despesas VALUES (5855558, '2015', '04473193000159', '2015-11-10', 'Nota Fiscal', '11', 'POSTO DA TORRE EIRELI EPP', '090287', '5240', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 212.990000000000009, 0, 212.990000000000009, 178952);
INSERT INTO despesas VALUES (5720010, '2015', '04473193000159', '2015-06-24', 'Nota Fiscal', '6', 'POSTO DA TORRE EIRELI EPP', '783226', '5072', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178952);
INSERT INTO despesas VALUES (5710582, '2015', '04473193000159', '2015-05-29', 'Nota Fiscal', '5', 'POSTO DA TORRE EIRELI EPP', '784063', '5062', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178952);
INSERT INTO despesas VALUES (5752025, '2015', '04473193000159', '2015-08-04', 'Nota Fiscal', '8', 'POSTO DA TORRE EIRELI EPP', '786721', '5118', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 185, 0, 185, 178952);
INSERT INTO despesas VALUES (5877463, '2015', '02952192000161', '2015-12-01', 'Nota Fiscal', '11', 'CABOTELECOM', '10001', '5280', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 210.090000000000003, 0, 210.090000000000003, 178949);
INSERT INTO despesas VALUES (5705086, '2015', '02952192000161', '2015-06-01', 'Nota Fiscal', '6', 'CABOTELECOM', '5307', '5058', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 210.090000000000003, 0, 210.090000000000003, 178949);
INSERT INTO despesas VALUES (5673019, '2015', '02952192000161', '2015-05-01', 'Nota Fiscal', '4', 'CABOTELECOM', '6338', '5021', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 210.090000000000003, 0, 210.090000000000003, 178949);
INSERT INTO despesas VALUES (5647576, '2015', '02952192000161', '2015-04-01', 'Nota Fiscal', '3', 'CABOTELECOM', '6520', '4993', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 214.530000000000001, 4.44000000000000039, 210.090000000000003, 178949);
INSERT INTO despesas VALUES (5733163, '2015', '02952192000161', '2015-07-01', 'Nota Fiscal', '6', 'CABOTELECOM', '6627', '5091', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 210.090000000000003, 0, 210.090000000000003, 178949);
INSERT INTO despesas VALUES (5790340, '2015', '02952192000161', '2015-09-01', 'Nota Fiscal', '8', 'CABOTELECOM', '6706', '5165', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 214.539999999999992, 0, 214.539999999999992, 178949);
INSERT INTO despesas VALUES (5638077, '2015', '02952192000161', '2015-03-01', 'Nota Fiscal', '2', 'CABOTELECOM', '7718', '4974', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 212.300000000000011, 10, 202.300000000000011, 178949);
INSERT INTO despesas VALUES (5841848, '2015', '02952192000161', '2015-11-01', 'Nota Fiscal', '10', 'CABOTELECOM', '7736', '5228', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 214.689999999999998, 0, 214.689999999999998, 178949);
INSERT INTO despesas VALUES (5818158, '2015', '02952192000161', '2015-10-01', 'Nota Fiscal', '9', 'CABOTELECOM', '8081', '5196', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 208.050000000000011, 0, 208.050000000000011, 178949);
INSERT INTO despesas VALUES (5893207, '2015', '02952192000161', '2016-01-01', 'Nota Fiscal', '12', 'CABOTELECOM', '9991', '5310', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 214.72999999999999, 4.63999999999999968, 210.090000000000003, 178949);
INSERT INTO despesas VALUES (5662270, '2015', '06278433000190', '2015-04-10', 'Nota Fiscal', '4', 'COMERCIAL DE ALIMENTOS GRANO LTDA', '100805', '5014', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 220, 0, 220, 178949);
INSERT INTO despesas VALUES (5720273, '2015', '06278433000190', '2015-05-28', 'Nota Fiscal', '5', 'COMERCIAL DE ALIMENTOS GRANO LTDA', '104379', '5082', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 338.5, 0, 338.5, 178949);
INSERT INTO despesas VALUES (5714112, '2015', '06278433000190', '2015-06-10', 'Nota Fiscal', '5', 'COMERCIAL DE ALIMENTOS GRANO LTDA', '105148', '5098', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 372, 152, 220, 178949);
INSERT INTO despesas VALUES (5739968, '2015', '06278433000190', '2015-06-25', 'Nota Fiscal', '7', 'COMERCIAL DE ALIMENTOS GRANO LTDA', '106503', '5108', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 378, 158, 220, 178949);
INSERT INTO despesas VALUES (5770081, '2015', '06278433000190', '2015-07-29', 'Nota Fiscal', '8', 'COMERCIAL DE ALIMENTOS GRANO LTDA', '108972', '5131', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 220, 0, 220, 178949);
INSERT INTO despesas VALUES (5626879, '2015', '06278433000190', '2015-03-03', 'Nota Fiscal', '2', 'COMERCIAL DE ALIMENTOS GRANO LTDA', '98315', '4959', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 220, 0, 220, 178949);
INSERT INTO despesas VALUES (5637959, '2015', '06278433000190', '2015-03-03', 'Nota Fiscal', '3', 'COMERCIAL DE ALIMENTOS GRANO LTDA', '98316', '4981', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 220, 0, 220, 178949);
INSERT INTO despesas VALUES (5821970, '2015', '08826869000100', '2015-09-28', 'Nota Fiscal', '9', 'Construtora Norte Brasil Ltda', '001345708', '5201', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 235.240000000000009, 0, 235.240000000000009, 178949);
INSERT INTO despesas VALUES (5790336, '2015', '08826869000100', '2015-08-27', 'Nota Fiscal', '8', 'Construtora Norte Brasil Ltda', '001357744', '5154', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 238.610000000000014, 0, 238.610000000000014, 178949);
INSERT INTO despesas VALUES (5887011, '2015', '08826869000100', '2015-12-09', 'Recibos/Outros', '12', 'Construtora Norte Brasil Ltda', '02/2015', '5307', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5638018, '2015', '08826869000100', '2015-03-06', 'Recibos/Outros', '3', 'Construtora Norte Brasil Ltda', '03/2015', '4994', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5799837, '2015', '08826869000100', '2015-08-05', 'Recibos/Outros', '8', 'Construtora Norte Brasil Ltda', '08/2015', '5168', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5895270, '2015', '08826869000100', '2015-12-28', 'Nota Fiscal', '12', 'Construtora Norte Brasil Ltda', '12/2015', '5313', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 243.919999999999987, 0, 243.919999999999987, 178949);
INSERT INTO despesas VALUES (5859244, '2015', '08826869000100', '2015-11-06', 'Recibos/Outros', '11', 'Construtora Norte Brasil Ltda', 's.n', '5246', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5733243, '2015', '08826869000100', '2015-07-06', 'Nota Fiscal', '6', 'Construtora Norte Brasil Ltda', 's/ número EL', '5098', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 244.909999999999997, 0, 244.909999999999997, 178949);
INSERT INTO despesas VALUES (5638043, '2015', '08826869000100', '2015-03-06', 'Nota Fiscal', '2', 'Construtora Norte Brasil Ltda', 's/n', '4982', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 208.120000000000005, 0, 208.120000000000005, 178949);
INSERT INTO despesas VALUES (5617482, '2015', '08826869000100', '2015-02-12', 'Recibos/Outros', '2', 'Construtora Norte Brasil Ltda', 's/n', '4958', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5647589, '2015', '08826869000100', '2015-04-02', 'Recibos/Outros', '4', 'Construtora Norte Brasil Ltda', 'S/N', '5021', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5705032, '2015', '08826869000100', '2015-06-08', 'Recibos/Outros', '5', 'Construtora Norte Brasil Ltda', 's/n', '5058', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 293.829999999999984, 0, 293.829999999999984, 178949);
INSERT INTO despesas VALUES (5705016, '2015', '08826869000100', '2015-06-08', 'Recibos/Outros', '6', 'Construtora Norte Brasil Ltda', 's/n', '5082', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5837625, '2015', '08826869000100', '2015-10-05', 'Recibos/Outros', '10', 'Construtora Norte Brasil Ltda', 's/n', '5215', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5661288, '2015', '08826869000100', '2015-04-10', 'Recibos/Outros', '3', 'Construtora Norte Brasil Ltda', 's/número', '5009', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 268.879999999999995, 0, 268.879999999999995, 178949);
INSERT INTO despesas VALUES (5688323, '2015', '08826869000100', '2015-05-08', 'Recibos/Outros', '5', 'Construtora Norte Brasil Ltda', 's/número', '5049', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5733182, '2015', '08826869000100', '2015-07-06', 'Recibos/Outros', '7', 'Construtora Norte Brasil Ltda', 's/número', '5119', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5759058, '2015', '08826869000100', '2015-08-10', 'Recibos/Outros', '7', 'Construtora Norte Brasil Ltda', 's/número', '5125', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 245.27000000000001, 0, 245.27000000000001, 178949);
INSERT INTO despesas VALUES (5802878, '2015', '08826869000100', '2015-09-04', 'Recibos/Outros', '9', 'Construtora Norte Brasil Ltda', 's/número', '5177', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 1333.6099999999999, 0, 1333.6099999999999, 178949);
INSERT INTO despesas VALUES (5841863, '2015', '08826869000100', '2015-11-06', 'Recibos/Outros', '10', 'Construtora Norte Brasil Ltda', 's/número', '5235', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 236.900000000000006, 0, 236.900000000000006, 178949);
INSERT INTO despesas VALUES (5877519, '2015', '08826869000100', '2015-12-09', 'Recibos/Outros', '11', 'Construtora Norte Brasil Ltda', 's/número', '5280', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 279.519999999999982, 0, 279.519999999999982, 178949);
INSERT INTO despesas VALUES (5688346, '2015', '08826869000100', '2015-05-18', 'Recibos/Outros', '4', 'Construtora Norte Brasil Ltda', 's/numero L', '5049', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 243.319999999999993, 0, 243.319999999999993, 178949);
INSERT INTO despesas VALUES (5638051, '2015', '13345728000105', '2015-03-25', 'Nota Fiscal', '3', 'EMYSOUTO PAPELARIA E INFORMATICA', '0881', '4974', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 533, 0, 533, 178949);
INSERT INTO despesas VALUES (5772061, '2015', '13345728000105', '2015-08-24', 'Nota Fiscal', '8', 'EMYSOUTO PAPELARIA E INFORMATICA', '1088', '5131', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 550.5, 0, 550.5, 178949);
INSERT INTO despesas VALUES (5885143, '2015', '13345728000105', '2015-12-22', 'Nota Fiscal', '12', 'EMYSOUTO PAPELARIA E INFORMATICA', '3643', '5307', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5864618, '2015', '04223486000188', '2015-12-02', 'Nota Fiscal', '12', 'FR COM E SRVIÇOS LTDA.', '024259', '5251', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 245, 0, 245, 178949);
INSERT INTO despesas VALUES (5679308, '2015', '18950309000108', '2015-05-07', 'Nota Fiscal', '5', 'Printideias BSB comércio e papelaria e serviços gráficos', '1454', '5032', 0, 'MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR', '', 40, 0, 40, 178949);
INSERT INTO despesas VALUES (5622578, '2015', '08473985000184', '2015-03-06', 'Nota Fiscal', '3', 'Alvares & Alvares Ltda', '505150', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 176.789999999999992, 0, 176.789999999999992, 178949);
INSERT INTO despesas VALUES (5800125, '2015', '14899379000128', '2015-09-20', 'Nota Fiscal', '9', 'auto posto central', '023823', '5167', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 140, 0, 140, 178949);
INSERT INTO despesas VALUES (5770790, '2015', '05901688000102', '2015-08-11', 'Nota Fiscal', '8', 'AUTO POSTO DOMINGOS COM. DERIV. DE PETRO. LTDA', '250396', '5131', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 20, 0, 20, 178949);
INSERT INTO despesas VALUES (5697849, '2015', '24187833000171', '2015-05-31', 'Nota Fiscal', '5', 'AUTO POSTO ESPACIAL LTDA', '024604', '5048', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 120, 0, 120, 178949);
INSERT INTO despesas VALUES (5720255, '2015', '24187833000171', '2015-06-21', 'Nota Fiscal', '6', 'AUTO POSTO ESPACIAL LTDA', '028172', '5072', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5758378, '2015', '24187833000171', '2015-08-07', 'Nota Fiscal', '8', 'AUTO POSTO ESPACIAL LTDA', '036604', '5119', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 128.02000000000001, 0, 128.02000000000001, 178949);
INSERT INTO despesas VALUES (5752658, '2015', '08533200000111', '2015-07-30', 'Nota Fiscal', '7', 'Auto Posto Irmãos Ltda', '066069', '5113', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 140.02000000000001, 0, 140.02000000000001, 178949);
INSERT INTO despesas VALUES (5885139, '2015', '00647440000135', '2015-12-17', 'Nota Fiscal', '12', 'AUTO SHOPPING QL 06 COM. DE PETRÓLEO LTDA', '645245', '5307', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178949);
INSERT INTO despesas VALUES (5790301, '2015', '10323902000112', '2015-09-12', 'Nota Fiscal', '9', 'C&S CJ SANTOS COMBUSTÍVEIS', '199680', '5152', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 131.030000000000001, 0, 131.030000000000001, 178949);
INSERT INTO despesas VALUES (5790299, '2015', '05564770000261', '2015-09-14', 'Nota Fiscal', '9', 'CARAU COMBUSTÍVEL LTDA', '003609', '5152', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 85, 0, 85, 178949);
INSERT INTO despesas VALUES (5893198, '2015', '05564770000261', '2015-12-22', 'Nota Fiscal', '12', 'CARAU COMBUSTÍVEL LTDA', '016742', '5310', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5777168, '2015', '05564770000261', '2015-08-31', 'Nota Fiscal', '8', 'CARAU COMBUSTÍVEL LTDA', '274418', '5135', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5777170, '2015', '05564770000261', '2015-08-29', 'Nota Fiscal', '8', 'CARAU COMBUSTÍVEL LTDA', '925406', '5135', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 122.150000000000006, 0, 122.150000000000006, 178949);
INSERT INTO despesas VALUES (5807219, '2015', '00306597007290', '2015-10-01', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS LTDA', '021804', '5177', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5722733, '2015', '00306597007290', '2015-06-25', 'Nota Fiscal', '6', 'Cascol Combustíveis Para Veículos  Ltda', '018824', '5073', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5847451, '2015', '00306597005247', '2015-11-11', 'Nota Fiscal', '11', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '29819', '5230', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 164.409999999999997, 0, 164.409999999999997, 178949);
INSERT INTO despesas VALUES (5688270, '2015', '00306597005670', '2015-05-14', 'Nota Fiscal', '5', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '024088', '5039', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178949);
INSERT INTO despesas VALUES (5704951, '2015', '00306597005670', '2015-06-01', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '024906', '5058', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5738502, '2015', '00306597005670', '2015-07-15', 'Nota Fiscal', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '026925', '5098', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5770796, '2015', '00306597005670', '2015-08-11', 'Nota Fiscal', '8', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '028155', '5131', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 80, 0, 80, 178949);
INSERT INTO despesas VALUES (5787057, '2015', '00306597005670', '2015-09-01', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '029219', '5149', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5787053, '2015', '00306597005670', '2015-09-03', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '029517', '5149', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5831141, '2015', '00306597005670', '2015-10-27', 'Nota Fiscal', '10', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '031612', '5212', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5880103, '2015', '00306597005670', '2015-12-15', 'Nota Fiscal', '12', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '033889', '5280', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5734013, '2015', '00306597006219', '2015-07-08', 'Nota Fiscal', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '019164', '5091', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5711675, '2015', '00306597006219', '2015-06-10', 'Nota Fiscal', '6', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '027883', '5061', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5733988, '2015', '00306597006219', '2015-07-03', 'Nota Fiscal', '7', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA', '029007', '5091', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178949);
INSERT INTO despesas VALUES (5880110, '2015', '00306597006308', '2015-12-02', 'Nota Fiscal', '12', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA', '028811', '5280', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5800115, '2015', '00306597004518', '2015-09-15', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA - Ipiranga', '029815', '5167', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5800114, '2015', '00306597004518', '2015-09-22', 'Nota Fiscal', '9', 'CASCOL COMBUSTIVEIS PARA VEICULOS LTDA - Ipiranga', '030178', '5167', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 152.259999999999991, 0, 152.259999999999991, 178949);
INSERT INTO despesas VALUES (5657625, '2015', '00306597000520', '2015-04-09', 'Nota Fiscal', '4', 'Cascol Combustíveis para Veículos Ltda.', '126538', '5001', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178949);
INSERT INTO despesas VALUES (5637828, '2015', '00306597000520', '2015-03-17', 'Nota Fiscal', '3', 'Cascol Combustíveis para Veículos Ltda.', '126724', '4974', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5626942, '2015', '00306597000520', '2015-03-11', 'Nota Fiscal', '3', 'Cascol Combustíveis para Veículos Ltda.', '126770', '4959', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 167.5, 0, 167.5, 178949);
INSERT INTO despesas VALUES (5617420, '2015', '00306597000520', '2015-02-26', 'Nota Fiscal', '2', 'Cascol Combustíveis para Veículos Ltda.', '126927', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5818139, '2015', '00306597000520', '2015-10-06', 'Nota Fiscal', '10', 'Cascol Combustíveis para Veículos Ltda.', '128660', '5194', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5657622, '2015', '00306597006308', '2015-04-15', 'Nota Fiscal', '4', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '019539', '5001', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5692066, '2015', '00306597006308', '2015-05-20', 'Nota Fiscal', '5', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '021167', '5043', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5692075, '2015', '00306597006308', '2015-05-26', 'Nota Fiscal', '5', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '021418', '5043', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 120.030000000000001, 0, 120.030000000000001, 178949);
INSERT INTO despesas VALUES (5697851, '2015', '00306597006308', '2015-05-28', 'Nota Fiscal', '5', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '021523', '5048', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5720253, '2015', '00306597006308', '2015-06-17', 'Nota Fiscal', '6', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '022355', '5072', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5597784, '2015', '00306597006308', '2015-02-01', 'Nota Fiscal', '2', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '10876', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5605801, '2015', '00306597006308', '2015-02-10', 'Nota Fiscal', '2', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '10935', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5597778, '2015', '00306597006308', '2015-02-04', 'Nota Fiscal', '2', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '12008', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5600859, '2015', '00306597006308', '2015-02-05', 'Nota Fiscal', '2', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '12043', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5609930, '2015', '00306597006308', '2015-02-24', 'Nota Fiscal', '2', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '12150', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5622566, '2015', '00306597006308', '2015-03-03', 'Nota Fiscal', '3', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '12271', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5622569, '2015', '00306597006308', '2015-03-05', 'Nota Fiscal', '3', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '12338', '4958', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5642914, '2015', '00306597006308', '2015-03-31', 'Nota Fiscal', '3', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '13209', '4981', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 209.189999999999998, 0, 209.189999999999998, 178949);
INSERT INTO despesas VALUES (5637836, '2015', '00306597006308', '2015-03-19', 'Nota Fiscal', '3', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '13510', '4974', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 174.610000000000014, 0, 174.610000000000014, 178949);
INSERT INTO despesas VALUES (5661266, '2015', '00306597006308', '2015-04-16', 'Nota Fiscal', '4', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '14131', '5007', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178949);
INSERT INTO despesas VALUES (5668500, '2015', '00306597006308', '2015-04-27', 'Nota Fiscal', '4', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '14215', '5012', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5671693, '2015', '00306597006308', '2015-05-05', 'Nota Fiscal', '5', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '14303', '5021', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 100, 0, 100, 178949);
INSERT INTO despesas VALUES (5679282, '2015', '00306597006308', '2015-05-06', 'Nota Fiscal', '5', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '14378', '5032', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 50, 0, 50, 178949);
INSERT INTO despesas VALUES (5679279, '2015', '00306597006308', '2015-05-12', 'Nota Fiscal', '5', 'CASCOL COMBUSTÍVEIS PARA VEÍCULOS LTDA.', '14379', '5032', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 150, 0, 150, 178949);
INSERT INTO despesas VALUES (5869729, '2015', '00306597002221', '2015-12-08', 'Nota Fiscal', '12', 'Cascol Combustiveis para Veiculos Ltda. 305 Sul.', '021618', '5256', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 170.02000000000001, 0, 170.02000000000001, 178949);
INSERT INTO despesas VALUES (5645759, '2015', '35304542000213', '2015-04-02', 'Nota Fiscal', '4', 'CIRNE PNEUS COMERCIO E SERVIÇOS LTDA', '009000', '4987', 0, 'COMBUSTÍVEIS E LUBRIFICANTES.', '', 139.990000000000009, 0, 139.990000000000009, 178949);


--
-- Name: despesas_id_despesa_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('despesas_id_despesa_seq', 1, false);


--
-- Data for Name: gabinetes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO gabinetes VALUES (178950, '230', '4', '230', '2', '3215-5230', 'dep.antoniojacome@camara.leg.br');
INSERT INTO gabinetes VALUES (178948, '840', '4', '840', '8', '3215-5840', 'dep.betorosado@camara.leg.br');
INSERT INTO gabinetes VALUES (141428, '706', '4', '706', '7', '3215-5706', 'dep.fabiofaria@camara.leg.br');
INSERT INTO gabinetes VALUES (141429, '528', '4', '528', '5', '3215-5528', 'dep.felipemaia@camara.leg.br');
INSERT INTO gabinetes VALUES (178951, '737', '4', '737', '7', '3215-5737', 'dep.rafaelmotta@camara.leg.br');
INSERT INTO gabinetes VALUES (141535, '446', '4', '446', '4', '3215-5446', 'dep.rogeriomarinho@camara.leg.br');
INSERT INTO gabinetes VALUES (178952, '435', '4', '435', '4', '3215-5435', 'dep.walteralves@camara.leg.br');
INSERT INTO gabinetes VALUES (178949, '439', '4', '439', '4', '3215-5439', 'dep.zenaidemaia@camara.leg.br');


--
-- Name: gabinetes_id_gabinete_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gabinetes_id_gabinete_seq', 1, false);


--
-- Data for Name: inscricoes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO inscricoes VALUES (141429, 1);
INSERT INTO inscricoes VALUES (178951, 1);
INSERT INTO inscricoes VALUES (141535, 1);
INSERT INTO inscricoes VALUES (178949, 1);
INSERT INTO inscricoes VALUES (178950, 2);
INSERT INTO inscricoes VALUES (178948, 2);
INSERT INTO inscricoes VALUES (141428, 2);
INSERT INTO inscricoes VALUES (178952, 2);


--
-- Data for Name: legislaturas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO legislaturas VALUES (-1823, '1823-04-17', '1823-11-12');
INSERT INTO legislaturas VALUES (-1821, '1821-12-01', '1822-12-31');
INSERT INTO legislaturas VALUES (1, '1826-04-29', '1830-04-24');
INSERT INTO legislaturas VALUES (2, '1830-04-25', '1834-04-24');
INSERT INTO legislaturas VALUES (3, '1834-04-25', '1838-04-24');
INSERT INTO legislaturas VALUES (4, '1838-04-25', '1842-04-24');
INSERT INTO legislaturas VALUES (5, '1842-04-25', '1844-05-24');
INSERT INTO legislaturas VALUES (6, '1844-12-24', '1848-04-24');
INSERT INTO legislaturas VALUES (7, '1848-04-25', '1849-02-19');
INSERT INTO legislaturas VALUES (8, '1849-12-15', '1853-04-14');
INSERT INTO legislaturas VALUES (9, '1853-04-15', '1857-04-14');
INSERT INTO legislaturas VALUES (10, '1857-04-15', '1861-04-14');
INSERT INTO legislaturas VALUES (11, '1861-04-15', '1863-05-12');
INSERT INTO legislaturas VALUES (12, '1863-12-14', '1867-04-14');
INSERT INTO legislaturas VALUES (13, '1867-04-15', '1868-07-18');
INSERT INTO legislaturas VALUES (14, '1869-04-15', '1872-05-22');
INSERT INTO legislaturas VALUES (15, '1872-11-13', '1876-11-12');
INSERT INTO legislaturas VALUES (16, '1876-12-13', '1878-04-11');
INSERT INTO legislaturas VALUES (17, '1878-11-27', '1881-06-30');
INSERT INTO legislaturas VALUES (18, '1881-12-13', '1884-09-03');
INSERT INTO legislaturas VALUES (19, '1885-02-11', '1885-09-26');
INSERT INTO legislaturas VALUES (20, '1886-04-15', '1889-06-15');
INSERT INTO legislaturas VALUES (21, '1889-11-02', '1889-11-15');
INSERT INTO legislaturas VALUES (22, '1891-06-10', '1894-04-17');
INSERT INTO legislaturas VALUES (23, '1894-04-18', '1897-04-17');
INSERT INTO legislaturas VALUES (24, '1897-04-18', '1900-04-17');
INSERT INTO legislaturas VALUES (25, '1900-04-18', '1903-04-17');
INSERT INTO legislaturas VALUES (26, '1903-04-18', '1906-04-17');
INSERT INTO legislaturas VALUES (27, '1906-04-18', '1909-04-17');
INSERT INTO legislaturas VALUES (28, '1909-04-18', '1912-04-17');
INSERT INTO legislaturas VALUES (29, '1912-04-18', '1915-04-02');
INSERT INTO legislaturas VALUES (30, '1915-04-03', '1918-04-17');
INSERT INTO legislaturas VALUES (31, '1918-04-18', '1921-04-14');
INSERT INTO legislaturas VALUES (32, '1921-04-15', '1924-04-14');
INSERT INTO legislaturas VALUES (33, '1924-04-15', '1927-04-14');
INSERT INTO legislaturas VALUES (34, '1927-04-15', '1930-04-14');
INSERT INTO legislaturas VALUES (35, '1930-04-15', '1930-11-11');
INSERT INTO legislaturas VALUES (36, '1934-07-21', '1935-04-27');
INSERT INTO legislaturas VALUES (37, '1935-04-28', '1937-11-10');
INSERT INTO legislaturas VALUES (38, '1946-09-23', '1951-03-09');
INSERT INTO legislaturas VALUES (39, '1951-03-10', '1955-01-31');
INSERT INTO legislaturas VALUES (40, '1955-02-01', '1959-01-31');
INSERT INTO legislaturas VALUES (41, '1959-02-01', '1963-01-31');
INSERT INTO legislaturas VALUES (42, '1963-02-01', '1967-01-31');
INSERT INTO legislaturas VALUES (43, '1967-02-01', '1971-01-31');
INSERT INTO legislaturas VALUES (44, '1971-02-01', '1975-01-31');
INSERT INTO legislaturas VALUES (45, '1975-02-01', '1979-01-31');
INSERT INTO legislaturas VALUES (46, '1979-02-01', '1983-01-31');
INSERT INTO legislaturas VALUES (47, '1983-02-01', '1987-01-31');
INSERT INTO legislaturas VALUES (48, '1987-02-01', '1991-01-31');
INSERT INTO legislaturas VALUES (49, '1991-02-01', '1995-01-31');
INSERT INTO legislaturas VALUES (50, '1995-02-01', '1999-01-31');
INSERT INTO legislaturas VALUES (51, '1999-02-01', '2003-01-31');
INSERT INTO legislaturas VALUES (52, '2003-02-01', '2007-01-31');
INSERT INTO legislaturas VALUES (53, '2007-02-01', '2011-01-31');
INSERT INTO legislaturas VALUES (54, '2011-02-01', '2015-01-31');
INSERT INTO legislaturas VALUES (55, '2015-02-01', '2019-01-31');


--
-- Name: legislaturas_id_legislatura_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('legislaturas_id_legislatura_seq', 1, false);


--
-- Data for Name: mandatos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO mandatos VALUES (178950, 55);
INSERT INTO mandatos VALUES (178948, 55);
INSERT INTO mandatos VALUES (141428, 55);
INSERT INTO mandatos VALUES (141429, 55);
INSERT INTO mandatos VALUES (178951, 55);
INSERT INTO mandatos VALUES (141535, 55);
INSERT INTO mandatos VALUES (178952, 55);
INSERT INTO mandatos VALUES (178949, 55);


--
-- Data for Name: partidos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO partidos VALUES (36898, 'Avante', 'AVANTE');
INSERT INTO partidos VALUES (36769, 'Democratas', 'DEM');
INSERT INTO partidos VALUES (36779, 'Partido Comunista do Brasil', 'PCdoB');
INSERT INTO partidos VALUES (36786, 'Partido Democrático Trabalhista', 'PDT');
INSERT INTO partidos VALUES (36761, 'Partido Ecológico Nacional', 'PEN');
INSERT INTO partidos VALUES (36793, 'Partido Humanista da Solidariedade', 'PHS');
INSERT INTO partidos VALUES (36887, 'Partido da Mulher Brasileira', 'PMB');
INSERT INTO partidos VALUES (36800, 'Partido do Movimento Democrático Brasileiro', 'PMDB');
INSERT INTO partidos VALUES (36801, 'Partido da Mobilização Nacional', 'PMN');
INSERT INTO partidos VALUES (36896, 'Podemos', 'PODE');
INSERT INTO partidos VALUES (36809, 'Partido Progressista', 'PP');
INSERT INTO partidos VALUES (36813, 'Partido Popular Socialista', 'PPS');
INSERT INTO partidos VALUES (36814, 'Partido da República', 'PR');
INSERT INTO partidos VALUES (36815, 'Partido Republicano Brasileiro', 'PRB');
INSERT INTO partidos VALUES (36763, 'Partido Republicano da Ordem Social', 'PROS');
INSERT INTO partidos VALUES (36824, 'Partido Republicano Progressista', 'PRP');
INSERT INTO partidos VALUES (36829, 'Partido Renovador Trabalhista Brasileiro', 'PRTB');
INSERT INTO partidos VALUES (36832, 'Partido Socialista Brasileiro', 'PSB');
INSERT INTO partidos VALUES (36833, 'Partido Social Cristão', 'PSC');
INSERT INTO partidos VALUES (36834, 'Partido Social Democrático', 'PSD');
INSERT INTO partidos VALUES (36835, 'Partido da Social Democracia Brasileira', 'PSDB');
INSERT INTO partidos VALUES (36836, 'Partido Social Democrata Cristão', 'PSDC');
INSERT INTO partidos VALUES (36837, 'Partido Social Liberal', 'PSL');
INSERT INTO partidos VALUES (36839, 'Partido Socialismo e Liberdade', 'PSOL');
INSERT INTO partidos VALUES (36844, 'Partido dos Trabalhadores', 'PT');
INSERT INTO partidos VALUES (36845, 'Partido Trabalhista Brasileiro', 'PTB');
INSERT INTO partidos VALUES (36846, 'Partido Trabalhista Cristão', 'PTC');
INSERT INTO partidos VALUES (36847, 'Partido Trabalhista do Brasil', 'PTdoB');
INSERT INTO partidos VALUES (36848, 'Partido Trabalhista Nacional', 'PTN');
INSERT INTO partidos VALUES (36851, 'Partido Verde', 'PV');
INSERT INTO partidos VALUES (36886, 'Rede Sustentabilidade', 'REDE');
INSERT INTO partidos VALUES (36852, 'Sem Partido', 'S.PART.');
INSERT INTO partidos VALUES (36765, 'Solidariedade', 'SD');


--
-- Name: partidos_id_partido_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('partidos_id_partido_seq', 1, false);


--
-- Data for Name: proposicoes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO proposicoes VALUES (2153662, 318, 7364, 2017, 'Requer a Inclusão na Pauta da Ordem do Dia do Plenário do PL Nº 2861/2008. ', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO proposicoes VALUES (2157872, 139, 8894, 2017, 'Cria o Fundo de Atendimento a Situações de Emergência e de Calamidade Pública Decorrentes de Secas (Fasec) e dispõe sobre seus objetivos e sua gestão e sobre as fontes e a aplicação dos respectivos recursos.', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO proposicoes VALUES (2158392, 318, 7507, 2017, 'Requer a inclusão na Ordem do Dia do PL nº 5957/2013, que altera a Lei nº 11.508, de 20 de julho de 2007, que "dispõe sobre o regime tributário, cambial e administrativo das Zonas de Processamento de Exportação, e dá outras providências".', NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO proposicoes VALUES (2160062, 148, 3273, 2017, 'Requer ao Senhor Ministro de Minas e Energia que solicite à Petrobras informar a esta Casa Legislativa seus planos para o estado do Rio Grande do Norte, especificamente quanto à devolução da Refinaria Potiguar Clara Camarão para a Diretoria de Exploração & Produção. ', NULL, NULL, NULL, NULL, NULL, NULL, NULL);


--
-- Name: proposicoes_id_proposicao_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('proposicoes_id_proposicao_seq', 1, false);


--
-- Data for Name: tipos_proposicao; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO tipos_proposicao VALUES (129, 'CON', 'Consulta', 'Consulta');
INSERT INTO tipos_proposicao VALUES (130, 'EMC', 'Emenda na Comissão', 'Emenda Apresentada na Comissão');
INSERT INTO tipos_proposicao VALUES (131, 'EMP', 'Emenda de Plenário', 'Emenda de Plenário');
INSERT INTO tipos_proposicao VALUES (132, 'EMS', 'Emenda/Substitutivo do Senado', 'Emenda/Substitutivo do Senado');
INSERT INTO tipos_proposicao VALUES (133, 'INC', 'Indicação', 'Indicação');
INSERT INTO tipos_proposicao VALUES (134, 'MSC', 'Mensagem', 'Mensagem');
INSERT INTO tipos_proposicao VALUES (135, 'PDC', 'Projeto de Decreto Legislativo', 'Projeto de Decreto Legislativo');
INSERT INTO tipos_proposicao VALUES (136, 'PEC', 'Proposta de Emenda à Constituição', 'Proposta de Emenda à Constituição (Art. 60 CF c/c art. 201 a 203, RICD)');
INSERT INTO tipos_proposicao VALUES (137, 'PET', 'Petição', 'Petição');
INSERT INTO tipos_proposicao VALUES (138, 'PFC', 'Proposta de Fiscalização e Controle', 'Proposta de Fiscalização e Controle');
INSERT INTO tipos_proposicao VALUES (139, 'PL', 'Projeto de Lei', 'Projeto de Lei');
INSERT INTO tipos_proposicao VALUES (140, 'PLP', 'Projeto de Lei Complementar', 'Projeto de Lei Complementar (Art. 61 CF)');
INSERT INTO tipos_proposicao VALUES (141, 'PRC', 'Projeto de Resolução', 'Projeto de Resolução');
INSERT INTO tipos_proposicao VALUES (142, 'PRN', 'Projeto de Resolução do Congresso Nacional', 'Projeto de Resolução (CN)');
INSERT INTO tipos_proposicao VALUES (143, 'RCP', 'Requerimento de Instituição de CPI', 'Requerimento de Instituição de Comissão Parlamentar de Inquérito');
INSERT INTO tipos_proposicao VALUES (144, 'REC', 'Recurso', 'Recurso');
INSERT INTO tipos_proposicao VALUES (145, 'REM', 'Reclamação', 'Reclamação');
INSERT INTO tipos_proposicao VALUES (146, 'REP', 'Representação', 'Representação');
INSERT INTO tipos_proposicao VALUES (147, 'REQ', 'Requerimento', '');
INSERT INTO tipos_proposicao VALUES (148, 'RIC', 'Requerimento de Informação', 'Requerimento de Informação (Art. 116, RICD)');
INSERT INTO tipos_proposicao VALUES (149, 'RPR', 'Representação', 'Representação');
INSERT INTO tipos_proposicao VALUES (150, 'REQ', 'Requerimento de Convocação', '');
INSERT INTO tipos_proposicao VALUES (151, 'SIT', 'Solicitação de Informação ao TCU', 'Solicitação de Informação ao TCU');
INSERT INTO tipos_proposicao VALUES (152, 'STF', 'Ofício', 'Ofício');
INSERT INTO tipos_proposicao VALUES (153, 'TVR', 'Ato de Concessão e Renovação de Concessão de Emissora de Rádio e Televisão', 'TVR');
INSERT INTO tipos_proposicao VALUES (154, 'REC', 'Recurso do Congresso Nacional', 'Recurso do Congresso Nacional');
INSERT INTO tipos_proposicao VALUES (171, 'INA', 'Indicação de Autoridade', 'Indicação de Autoridade');
INSERT INTO tipos_proposicao VALUES (181, 'OF', 'Ofício', 'Ofício');
INSERT INTO tipos_proposicao VALUES (185, 'P.C', 'Parecer (CD)', 'Parecer (CD)');
INSERT INTO tipos_proposicao VALUES (187, 'PAR', 'Parecer de Comissão', 'Parecer de Comissão');
INSERT INTO tipos_proposicao VALUES (189, 'MAN', 'Manifestação do Relator', 'Manifestação do Relator');
INSERT INTO tipos_proposicao VALUES (190, 'PRL', 'Parecer do Relator', 'Parecer Relator');
INSERT INTO tipos_proposicao VALUES (191, 'PRV', 'Parecer Vencedor', 'Parecer Vencedor');
INSERT INTO tipos_proposicao VALUES (192, 'PPP', 'Parecer Proferido em Plenário', 'Parecer Proferido em Plenário');
INSERT INTO tipos_proposicao VALUES (193, 'PRR', 'Parecer Reformulado', 'Parecer Reformulado');
INSERT INTO tipos_proposicao VALUES (195, 'CVO', 'Complementação de Voto', 'Complementação de Voto');
INSERT INTO tipos_proposicao VALUES (196, 'PES', 'Parecer às emendas apresentadas ao Substitutivo do Relator', 'Parecer às emendas apresentadas ao Substitutivo do Relator ');
INSERT INTO tipos_proposicao VALUES (197, 'RDF', 'Redação Final', 'Redação Final');
INSERT INTO tipos_proposicao VALUES (201, 'MAN', 'Manifestação pela Prejudicialidade da Matéria', 'Manifestação pela Prejudicialidade da Matéria');
INSERT INTO tipos_proposicao VALUES (202, 'MAN', 'Manifestação pela Incompetência da Comissão', 'Manifestação pela Incompetência da Comissão');
INSERT INTO tipos_proposicao VALUES (211, 'PRF', 'Projeto de Resolução do Senado Federal', 'Projeto de Resolução do Senado Federal');
INSERT INTO tipos_proposicao VALUES (234, 'RTV', 'Mensagem de Rádio e Televisão', 'Mensagem de Rádio e Televisão');
INSERT INTO tipos_proposicao VALUES (246, 'CST', 'CST', 'CST');
INSERT INTO tipos_proposicao VALUES (248, 'NINF', 'Não Informada', 'Não Informada');
INSERT INTO tipos_proposicao VALUES (249, 'OFT', 'OFT', 'OFT');
INSERT INTO tipos_proposicao VALUES (253, 'SGM', 'Ofício da Mesa', 'Ofício da Mesa');
INSERT INTO tipos_proposicao VALUES (254, 'DIS', 'Discurso', 'Discurso');
INSERT INTO tipos_proposicao VALUES (255, 'SBT', 'Substitutivo', 'Substitutivo');
INSERT INTO tipos_proposicao VALUES (256, 'SBE', 'Subemenda', 'Subemenda');
INSERT INTO tipos_proposicao VALUES (257, 'EMR', 'Emenda de Relator', 'Emenda de Relator');
INSERT INTO tipos_proposicao VALUES (258, 'ESB', 'Emenda ao Substitutivo', 'Emenda ao Substitutivo');
INSERT INTO tipos_proposicao VALUES (260, 'VTS', 'Voto em Separado', 'Voto em Separado');
INSERT INTO tipos_proposicao VALUES (261, 'DTQ', 'Destaque', 'Destaque');
INSERT INTO tipos_proposicao VALUES (262, 'REL', 'Relatório de Subcomissão', 'Relatório de Subcomissão');
INSERT INTO tipos_proposicao VALUES (270, 'DVT', 'Declaração de Voto', 'Declaração de Voto');
INSERT INTO tipos_proposicao VALUES (273, 'EML', 'Emenda à LDO', 'Emenda à LDO');
INSERT INTO tipos_proposicao VALUES (276, 'SDL', 'Sugestão de Emenda à LDO - CLP', 'Sugestão de Emenda à LDO');
INSERT INTO tipos_proposicao VALUES (285, 'SUG', 'Sugestão', 'Sugestão');
INSERT INTO tipos_proposicao VALUES (286, 'SUM', 'Súmula', 'Súmula');
INSERT INTO tipos_proposicao VALUES (287, 'EMO', 'Emenda ao Orçamento', 'Emenda ao Orçamento');
INSERT INTO tipos_proposicao VALUES (288, 'SOA', 'Sugestão de Emenda ao Orçamento - CLP', 'Sugestão de Emenda ao Orçamento');
INSERT INTO tipos_proposicao VALUES (289, 'REL', 'Relatório de CPI', 'Relatório de CPI');
INSERT INTO tipos_proposicao VALUES (290, 'EMD', 'Emenda', 'Emenda');
INSERT INTO tipos_proposicao VALUES (291, 'MPV', 'Medida Provisória', 'Medida Provisória');
INSERT INTO tipos_proposicao VALUES (292, 'REL', 'Relatório', 'Relatório');
INSERT INTO tipos_proposicao VALUES (293, 'REQ', 'Requerimento de Sessão Solene', '');
INSERT INTO tipos_proposicao VALUES (294, 'REQ', 'Requerimento de Audiência Pública', '');
INSERT INTO tipos_proposicao VALUES (295, 'DEN', 'Denúncia', 'Denúncia');
INSERT INTO tipos_proposicao VALUES (296, '', 'D) PARECERES, MANIFESTAÇÕES E REDAÇÃO FINAL', 'E) PARECERES, MANIFESTAÇÕES E REDAÇÃO FINAL');
INSERT INTO tipos_proposicao VALUES (297, '', 'C) EMENDAS (RICD Cap. V)', 'D) EMENDAS (RICD Cap. V)');
INSERT INTO tipos_proposicao VALUES (298, '', 'H) OUTRAS PROPOSIÇÕES ACESSÓRIAS', 'OUTRAS PROPOSIÇÕES ACESSÓRIAS');
INSERT INTO tipos_proposicao VALUES (299, '', 'E) REQUERIMENTOS (RICD Cap IV)', 'F) REQUERIMENTOS (RICD Cap IV)');
INSERT INTO tipos_proposicao VALUES (301, '', 'A) PROPOSIÇÕES CF/88 Art. 59', 'A) PROPOSIÇÕES CF/88 Art. 59');
INSERT INTO tipos_proposicao VALUES (302, '', 'B) PROPOSIÇÕES CF/88 Arts 58, 70 e 223, e RICD Art 100.', 'B) PROPOSIÇÕES CF/88 Arts 58, 70 e 233, e RICD Art 100.');
INSERT INTO tipos_proposicao VALUES (303, '', 'F) SUGESTÕES', 'G) SUGESTÕES');
INSERT INTO tipos_proposicao VALUES (304, 'REQ', 'Requerimento de Apensação', 'Ar. 142, RICD');
INSERT INTO tipos_proposicao VALUES (305, 'REQ', 'Requerimento de Desapensação', '');
INSERT INTO tipos_proposicao VALUES (306, 'REQ', 'Requerimento de Audiência solicitada por Deputado', '');
INSERT INTO tipos_proposicao VALUES (307, 'REQ', 'Requerimento de Audiência solicitada por Comissão ou Deputado', '');
INSERT INTO tipos_proposicao VALUES (308, 'REQ', 'Requerimento de Redistribuição', '');
INSERT INTO tipos_proposicao VALUES (310, 'REQ', 'Requerimento de Retirada de assinatura em proposição de iniciativa coletiva', '');
INSERT INTO tipos_proposicao VALUES (311, 'REQ', 'Requerimento de Retirada de proposição de iniciativa individual', '');
INSERT INTO tipos_proposicao VALUES (312, 'REQ', 'Requerimento de Retirada de Proposição de Iniciativa Coletiva', '');
INSERT INTO tipos_proposicao VALUES (313, 'REQ', 'Requerimento de Retirada de assinatura em proposição que não seja de iniciativa coletiva', '');
INSERT INTO tipos_proposicao VALUES (314, 'REQ', 'Requerimento de Envio de proposições pendentes de parecer à Comissão seguinte ou ao Plenário', '');
INSERT INTO tipos_proposicao VALUES (315, 'REQ', 'Requerimento de Retirada do requerimento de urgência (matéria com requerimento apresentado e não votado)', '');
INSERT INTO tipos_proposicao VALUES (316, 'REQ', 'Requerimento de Retirada do requerimento de informação', '');
INSERT INTO tipos_proposicao VALUES (317, 'REQ', 'Requerimento de Constituição de Comissão Parlamentar de Inquerito (CPI)', '');
INSERT INTO tipos_proposicao VALUES (318, 'REQ', 'Requerimento de Inclusão na Ordem do Dia', 'Inclusão na Ordem do Dia (Art. 135 c/c 114, XIV, RICD)');
INSERT INTO tipos_proposicao VALUES (319, 'REQ', 'Requerimento de Retirada de proposição', 'Retirada de proposição com parecer (Art. 104, c/c art. 114, V e VII, RICD)');
INSERT INTO tipos_proposicao VALUES (453, 'RLP', 'Relatório Prévio', '');
INSERT INTO tipos_proposicao VALUES (321, 'REQ', 'Requerimento de Extinção do regime de urgência (matéria com urgência votada)', 'Extinção do regime de urgência (Art. 156, c/c art. 104, RICD)');
INSERT INTO tipos_proposicao VALUES (322, 'REQ', 'Requerimento de Tramitação de proposição em regime de prioridade', '');
INSERT INTO tipos_proposicao VALUES (323, 'REQ', 'Requerimento de Dispensa de interstício para inclusão de matéria prevista no art. 17, I, s (Agenda Mensal) na Ordem do Dia', 'Dispensa de interstício para inclusão na Ordem do Dia (Art. 150, § único, RICD)');
INSERT INTO tipos_proposicao VALUES (324, 'REQ', 'Requerimento de Destaque para votação em separado de parte de proposição (DVS)', '');
INSERT INTO tipos_proposicao VALUES (327, 'REQ', 'Requerimento de Retirada da OD de proposições com pareceres favoraveis', '');
INSERT INTO tipos_proposicao VALUES (328, 'REQ', 'Requerimento de Retirada da OD de proposição nela incluída', 'Retirada da OD de proposição nela incluída (Art. 117, VI, RICD)');
INSERT INTO tipos_proposicao VALUES (329, 'REQ', 'Requerimento de Adiamento de discussão', 'Adiamento de discussão nos termos do art. 177, c/c art. 101, II,2, RICD.');
INSERT INTO tipos_proposicao VALUES (330, 'REQ', 'Requerimento de Dispensa da discussão', 'Dispensa da discussão (Art. 101, II, 2, RICD)');
INSERT INTO tipos_proposicao VALUES (331, 'REQ', 'Requerimento de Encerramento de Discussão', 'Encerramento de discussão (Art. 178, § 2º, c/c art. 101, II, 2, RICD)');
INSERT INTO tipos_proposicao VALUES (332, 'REQ', 'Requerimento de Votação por determinado processo', 'Votação por determinado processo (Art. 101, II, 3, c/c art. 189, § 3º, RICD)');
INSERT INTO tipos_proposicao VALUES (333, 'REQ', 'Requerimento de Votação  parcelada da proposição', 'Votação em globo ou parcelada (Art. 101, II, 3, c/c art. 189, § 3º RICD)');
INSERT INTO tipos_proposicao VALUES (334, 'REQ', 'Requerimento de Verificação de votação', 'Verificação de votação (Art. art. 185, §5º, RICD)');
INSERT INTO tipos_proposicao VALUES (335, 'REQ', 'Requerimento de Votação por escrutínio secreto', 'Votação por escrutínio secreto (Art. 188, II, RICD)');
INSERT INTO tipos_proposicao VALUES (336, 'REQ', 'Requerimento de Adiamento da votação', 'Adiamento da votação nos termos do Art. 193º c/c 117, X do RICD.');
INSERT INTO tipos_proposicao VALUES (337, 'REQ', 'Requerimento de Preferência para votação ou discussão de uma proposição', 'Preferência para votação ou discussão de uma proposição (Art. 160, RICD)');
INSERT INTO tipos_proposicao VALUES (338, 'REQ', 'Requerimento de Dispensa do avulso da redação final', '');
INSERT INTO tipos_proposicao VALUES (339, 'REQ', 'Requerimento de Reconstituição de proposição', '');
INSERT INTO tipos_proposicao VALUES (340, 'REQ', 'Requerimento de Inclusão na Ordem do Dia de proposição (Durante o período ordinário)', '');
INSERT INTO tipos_proposicao VALUES (341, 'REQ', 'Requerimento de Publicação de Parecer de Comissão aprovado', '');
INSERT INTO tipos_proposicao VALUES (342, 'REQ', 'Requerimento de Reabertura de discussão de projeto de Sessão Legislativa anterior', '');
INSERT INTO tipos_proposicao VALUES (343, 'REQ', 'Requerimento de Transformação de Sessão Plenaria em Comissão Geral', '');
INSERT INTO tipos_proposicao VALUES (344, 'REQ', 'Requerimento de Retificação de Ata', '');
INSERT INTO tipos_proposicao VALUES (345, 'REQ', 'Requerimento de Prorrogação de sessão', 'Prorrogação de sessão (Art. 72, RICD)');
INSERT INTO tipos_proposicao VALUES (346, 'REQ', 'Requerimento de Prorrogação da Ordem do Dia', 'Prorrogação da Ordem do Dia (Art. 84, RICD)');
INSERT INTO tipos_proposicao VALUES (347, 'REQ', 'Requerimento de Convocação de Sessões Extraordinarias para matérias constantes do ato de convocação', '');
INSERT INTO tipos_proposicao VALUES (348, 'REQ', 'Requerimento de Prorrogação de prazo de Comissão Temporária', '');
INSERT INTO tipos_proposicao VALUES (349, 'REQ', 'Requerimento de Constituição de Comissão Externa', '');
INSERT INTO tipos_proposicao VALUES (350, 'REQ', 'Requerimento de Realização de Sessão Extraordinária', '');
INSERT INTO tipos_proposicao VALUES (351, 'REQ', 'Requerimento de Realização de Sessão secreta', '');
INSERT INTO tipos_proposicao VALUES (353, 'REQ', 'Requerimento de Não realização de sessão solene em determinado dia', '');
INSERT INTO tipos_proposicao VALUES (354, 'REQ', 'Requerimento de Voto de regozijo ou louvor', '');
INSERT INTO tipos_proposicao VALUES (355, 'REQ', 'Requerimento de Voto de pesar', '');
INSERT INTO tipos_proposicao VALUES (356, 'REQ', 'Requerimento de Convocação de Ministro de Estado no Plenário', '');
INSERT INTO tipos_proposicao VALUES (357, 'REQ', 'Requerimento de Quebra de sigilo (Requerimentos não especificados no RICD', '');
INSERT INTO tipos_proposicao VALUES (358, 'REQ', 'Requerimento de Encaminha copia de Relatorio Final de C. Temporaria', '');
INSERT INTO tipos_proposicao VALUES (359, 'REQ', 'Requerimento de Constituição de Comissão Especial de PEC', '');
INSERT INTO tipos_proposicao VALUES (360, 'REQ', 'Requerimento de Inserção nos Anais', '');
INSERT INTO tipos_proposicao VALUES (361, 'REQ', 'Requerimento de Publicação de documentos discursos de outro poder nao lidos na integra por deputado', '');
INSERT INTO tipos_proposicao VALUES (362, 'REQ', 'Requerimento de Adocão de providências em face da ausência de resposta no prazo constitucional a RIC', 'Art. 50, § 2º da CF c/c art. 105, RICD.');
INSERT INTO tipos_proposicao VALUES (363, 'REQ', 'Requerimento de Desarquivamento de Proposições', '');
INSERT INTO tipos_proposicao VALUES (364, 'REQ', 'Requerimento de Afastamento para tratamento de saude superior a 120 dias.', 'Art. 235, II, RICD.');
INSERT INTO tipos_proposicao VALUES (365, 'REQ', 'Requerimento de Afastamento para tratamento de saúde inferior a 120 dias.', 'Art. 235, II, RICD.');
INSERT INTO tipos_proposicao VALUES (366, 'REQ', 'Requerimento de Afastamento por licença de saude e consecutivamente afastamento para tratar de assunto particular superior a 120 dias.', 'Art. 235, II e III, RICD.');
INSERT INTO tipos_proposicao VALUES (368, 'REQ', 'Requerimento de Afastamento para investidura em cargo publico', 'Art. 56, inciso I da CF c/c com art. 235, IV, RICD.');
INSERT INTO tipos_proposicao VALUES (369, 'REQ', 'Requerimento de Prorrogação de licença para tratamento de saúde (licença superior a 120 dias)', '');
INSERT INTO tipos_proposicao VALUES (370, 'REQ', 'Requerimento de Interrupção da licença superior a 120 dias', '');
INSERT INTO tipos_proposicao VALUES (371, 'REQ', 'Requerimento de Justificativa de falta', '');
INSERT INTO tipos_proposicao VALUES (372, 'REC', 'Recurso contra devolução de requerimento de CPI (Art. 35, § 2º, RICD)', 'Contra devolução de requerimento de CPI (Art. 35, § 1º, RICD)');
INSERT INTO tipos_proposicao VALUES (373, 'REC', 'Recurso contra apreciação conclusiva de comissão (Art. 58, § 1º c/c art. 132, § 2º, RICD)', 'Contra apreciação conclusiva de comissão (Art. 58, § 1º, RICD)');
INSERT INTO tipos_proposicao VALUES (374, 'REC', 'Recurso contra apreciação conclusiva com pareceres contrarios (Art. 133, RICD)', 'Contra apreciação conclusiva com pareceres contrarios (Art. 133, RICD)');
INSERT INTO tipos_proposicao VALUES (375, 'REC', 'Recurso contra parecer terminativo de comissão (Art. 132, § 2º c/c art. 144, caput, RICD)', 'Contra parecer terminativo de comissão (Art. 132, § 2º c/c art. 144, caput, RICD)');
INSERT INTO tipos_proposicao VALUES (376, 'REC', 'Recurso contra devolução de proposição (Art. 137, § 2º, RICD)', 'Contra devolução de proposição (Art. 137, § 2º, RICD)');
INSERT INTO tipos_proposicao VALUES (377, 'REC', 'Recurso contra deferimento/indeferimento de audiencia (Art. 140, I, RICD)', 'Contra deferimento/indeferimento de audiencia (Art. 140, I, RICD)');
INSERT INTO tipos_proposicao VALUES (378, 'REC', 'Recurso contra redistribuição de proposição (Art. 141, RICD)', 'Contra redistribuição de proposição (Art. 141, § 4º, RICD)');
INSERT INTO tipos_proposicao VALUES (379, 'REC', 'Recurso contra apensação/desapensação de proposição (Art. 142, I, RICD)', 'Contra apensação/desapensação de proposição (Art. 142, I, RICD)');
INSERT INTO tipos_proposicao VALUES (380, 'REC', 'Recurso contra deferimento/indeferimento retirada proposição (Art. 104, caput, RICD)', 'Contra deferimento/indeferimento retirada proposição (Art. 104, caput, RICD)');
INSERT INTO tipos_proposicao VALUES (381, 'REC', 'Recurso contra declaração de prejudicialidade. (Art. 164, § 2º, RICD)', 'Contra declaração de prejudicialidade. (Art. 164, § 2º, RICD)');
INSERT INTO tipos_proposicao VALUES (382, 'REC', 'Recurso contra decisão do Presidente da CD em Questao de Ordem (Art. 95, § 8º, RICD)', 'Contra decisão do Presidente da CD em Questao de Ordem (Art. 95, § 8º, RICD)');
INSERT INTO tipos_proposicao VALUES (383, 'REC', 'Recurso contra decisão de Presidente de Comissão em Questão de Ordem (Art. 57, XXI c/c art. 17, III, f, RICD)', 'Contra decisão de Presidente de Comissão em Questão de Ordem (Art. 57, XXI c/c art. 17, III, f, RICD)');
INSERT INTO tipos_proposicao VALUES (384, 'REC', 'Recurso contra indeferimento de Requerimento de Infomação (Art. 115, parágrafo único, RICD)', 'Contra indeferimento de Requerimento de Infomação (Art. 115, parágrafo único, RICD)');
INSERT INTO tipos_proposicao VALUES (385, 'REC', 'Recurso contra nao recebimento de emenda (Art. 125, caput, RICD)', 'Contra nao recebimento de emenda (Art. 125, caput, RICD)');
INSERT INTO tipos_proposicao VALUES (386, 'REC', 'Recurso contra improcedencia de retificação de ata (Art. 80, § 1º, RICD)', 'Contra improcedencia de retificação de ata (Art. 80, § 1º, RICD)');
INSERT INTO tipos_proposicao VALUES (387, 'REC', 'Recurso contra indeferimento de requerimento para publicação em ata (Art. 98, § 3º, RICD)', 'Contra indeferimento de requerimento para publicação em ata (Art. 98, § 3º, RICD)');
INSERT INTO tipos_proposicao VALUES (388, 'REC', 'Recurso contra a não publicação de pronunciamento ou expressão (Art. 98, 6º, RICD)', 'Contra a não publicação de pronunciamento ou expressão (Art. 98, 6º, RICD)');
INSERT INTO tipos_proposicao VALUES (389, 'REC', 'Recurso contra nao recebimento de denuncia crime responsabilidade (Art. 218, § 3º, RICD)', 'Contra nao recebimento de denuncia crime responsabilidade (Art. 218, § 3º, RICD)');
INSERT INTO tipos_proposicao VALUES (390, 'PLV', 'Projeto de Lei de Conversão', 'Projeto de Lei de Conversão');
INSERT INTO tipos_proposicao VALUES (391, 'REQ', 'Requerimento de Urgência (Art. 154 do RICD)', 'Urgencia (Art. 154 do RICD)');
INSERT INTO tipos_proposicao VALUES (392, 'REQ', 'Requerimento de Urgência (Art. 155 do RICD)', 'Urgência (Art. 155 do RICD)');
INSERT INTO tipos_proposicao VALUES (393, 'REQ', 'Requerimento de Adiamento de discussão em regime de urgência', 'Aditamento de discussão em regime de urgência nos termos do art. 177, §1º do RICD.');
INSERT INTO tipos_proposicao VALUES (394, 'PDC', 'Projeto de Decreto Legislativo de Medida Provisória', 'Medida Provisória (Art. 62, § 3º da CF)');
INSERT INTO tipos_proposicao VALUES (395, 'PDC', 'Projeto de Decreto Legislativo de Referendo ou Plebiscito', 'Plebiscito (Art. 49, XV da CF c/c o art. 3º Lei 9.709/98)');
INSERT INTO tipos_proposicao VALUES (396, 'PDC', 'Projeto de Decreto Legislativo de Concessão, Renovação e Permissão de Radio/TV', 'Concessão/Renovação de Radio/TV (Art. 49, XII c/c 223 da CF)');
INSERT INTO tipos_proposicao VALUES (397, 'PDC', 'Projeto de Decreto Legislativo de Acordos, tratados ou atos internacionais', 'Acordos, tratados ou atos internacionais (Art. 49, I da CF)');
INSERT INTO tipos_proposicao VALUES (398, 'PDC', 'Projeto de Decreto Legislativo de Indicação de Autoridade ao TCU', 'Indicação de Autoridade ao TCU (Art. 49, XIII da CF)');
INSERT INTO tipos_proposicao VALUES (400, 'PRC', 'Projeto de Resolução de Criação de CPI', 'Criação de CPI (Art. 35 do RICD)');
INSERT INTO tipos_proposicao VALUES (401, 'MSC', 'Mensagem de Concessão ou Renovação de Rádio e TV', 'Concessão de Rádio e TV (Art. 49, XII c/c 223 CF)');
INSERT INTO tipos_proposicao VALUES (402, 'REC', 'Recurso contra aplicação de censura verbal (Art. 11, Parágrafo único do CEDP)', 'Contra aplicação de censura verbal (Art. 11, Parágrafo único do CEDP)');
INSERT INTO tipos_proposicao VALUES (403, 'MSC', 'Mensagem de Comunica ausência do país', 'Comunica ausência do país');
INSERT INTO tipos_proposicao VALUES (404, 'MSC', 'Mensagem de Cancelamento de Urgência', 'Cancelamento de Urgência');
INSERT INTO tipos_proposicao VALUES (405, 'MSC', 'Mensagem de Retirada de proposição', 'Retirada de proposição');
INSERT INTO tipos_proposicao VALUES (406, 'MSC', 'Mensagem de Solicitação de urgência', 'Solicitação de urgência ');
INSERT INTO tipos_proposicao VALUES (407, 'PDC', 'Projeto de Decreto Legislativo de Programação Monetária', 'Programação Monetária (Lei nº 9.069/95)');
INSERT INTO tipos_proposicao VALUES (408, 'PDC', 'Projeto de Decreto Legislativo de Sustação de Atos Normativos do Poder Executivo', 'Susta atos normativos do Poder Executivo.');
INSERT INTO tipos_proposicao VALUES (409, 'AV', 'Demonstrativo de emissão do real', 'Demonstrativo de emissão do real (Lei nº 9.069/95)');
INSERT INTO tipos_proposicao VALUES (410, 'MSC', 'Mensagem de Indicação de Líder', 'Indicação de Líder');
INSERT INTO tipos_proposicao VALUES (411, 'MSC', 'Mensagem de Acordos, convênios, tratados e atos internacionais', 'Acordos, convênios, tratados e atos internacionais');
INSERT INTO tipos_proposicao VALUES (412, 'MSC', 'Mensagem de Restituição de Autógrafos', 'Restituição de Autógrafos');
INSERT INTO tipos_proposicao VALUES (413, 'REQ', 'Requerimento de Retirada de proposição sem parecer', '');
INSERT INTO tipos_proposicao VALUES (414, 'MSC', 'Mensagem de ausência do país por mais de 15 dias', 'Mensagem de ausência do país por mais de 15 dias (Art. 49, III, CF)');
INSERT INTO tipos_proposicao VALUES (415, 'MSC', 'Mensagem de ausência do país por menos de 15 dias', 'Mensagem de ausência do país por menos de 15 dias  (Art. 49, III, CF)');
INSERT INTO tipos_proposicao VALUES (417, 'TVR', 'Autorização - Rádio Comunitária', 'Autorização - Rádio Comunitária');
INSERT INTO tipos_proposicao VALUES (418, 'TVR', 'Concessão - Rádio Ondas Curtas', 'Concessão - Rádio Ondas Curtas');
INSERT INTO tipos_proposicao VALUES (419, 'TVR', 'Concessão - Rádio Ondas Médias', 'Concessão - Rádio Ondas Médias');
INSERT INTO tipos_proposicao VALUES (420, 'TVR', 'Concessão Rádio Ondas Médias Educativa', 'Concessão Rádio Ondas Médias Educativa');
INSERT INTO tipos_proposicao VALUES (421, 'TVR', 'Concessão Rádio Ondas Tropicais', 'Concessão Rádio Ondas Tropocais');
INSERT INTO tipos_proposicao VALUES (422, 'TVR', 'Concessão Radiodifusão Sons e Imagens', 'Concessão Radiodifusão Sons e Imagens');
INSERT INTO tipos_proposicao VALUES (423, 'TVR', 'Concessão TV Educativa', 'Concessão TV Educativa');
INSERT INTO tipos_proposicao VALUES (424, 'TVR', 'Permissão Frequência Modulada Educativa', 'Permissão Frequência Modulada Educativa');
INSERT INTO tipos_proposicao VALUES (425, 'TVR', 'Permissão Rádio Frequência Modulada', 'Permissão Rádio Frequência Modulada');
INSERT INTO tipos_proposicao VALUES (426, 'TVR', 'Permissão Rádio Ondas Médias Local', 'Permissão Rádio Ondas Médias Local');
INSERT INTO tipos_proposicao VALUES (427, 'TVR', 'Renovação Rádio Comunitária', 'Renovação Rádio Comunitária');
INSERT INTO tipos_proposicao VALUES (428, 'TVR', 'Renovação Rádio Frequência Modulada', 'Renovação Rádio Frequência Modulada');
INSERT INTO tipos_proposicao VALUES (429, 'TVR', 'Renovação Rádio Frequência Modulada Educativa', 'Renovação Rádio Frequência Modulada Educativa');
INSERT INTO tipos_proposicao VALUES (430, 'TVR', 'Renovação Rádio Ondas Curtas', 'Renovação Rádio Ondas Curtas');
INSERT INTO tipos_proposicao VALUES (431, 'TVR', 'Renovação Rádio Ondas Médias', 'Renovação Rádio Ondas Médias');
INSERT INTO tipos_proposicao VALUES (432, 'TVR', 'Renovação Rádio Ondas Médias Local', 'Renovação Rádio Ondas Médias Local');
INSERT INTO tipos_proposicao VALUES (433, 'TVR', 'Renovação Rádio Ondas Médias Educativa', 'Renovação Rádio Ondas Médias Educativa');
INSERT INTO tipos_proposicao VALUES (434, 'TVR', 'Renovação Rádio Ondas Tropicais', 'Renovação  Rádio Ondas Tropicais');
INSERT INTO tipos_proposicao VALUES (435, 'TVR', 'Renovação TV Sons e Imagens', 'Renovação TV Sons e Imagens');
INSERT INTO tipos_proposicao VALUES (436, 'TVR', 'Renovação TV Educativa', 'Renovação TV Educativa');
INSERT INTO tipos_proposicao VALUES (437, 'MSC', 'Mensagem de Cumprimento de meta', 'Cumprimento de meta');
INSERT INTO tipos_proposicao VALUES (439, 'DCR', 'Denúncia por crime de responsabilidade', 'Denúncia por crime de responsabilidade');
INSERT INTO tipos_proposicao VALUES (440, '', 'J) NÃO PROPOSIÇÃO', 'Não Proposição');
INSERT INTO tipos_proposicao VALUES (441, 'REQ', 'Requerimento de Moção', '');
INSERT INTO tipos_proposicao VALUES (442, 'PEP', 'Parecer às Emendas de Plenario', '');
INSERT INTO tipos_proposicao VALUES (443, 'PSS', 'Parecer às Emendas ou ao Substitutivo do Senado', '');
INSERT INTO tipos_proposicao VALUES (444, 'PRC', 'Projeto de Resolução de Alteração do Regimento e outros', '');
INSERT INTO tipos_proposicao VALUES (445, 'NIC', 'Norma Interna', '');
INSERT INTO tipos_proposicao VALUES (448, 'REQ', 'Requerimento não previsto', '');
INSERT INTO tipos_proposicao VALUES (449, 'MSC', 'Mensagem de Implementação da Lei 10.147/00', '');
INSERT INTO tipos_proposicao VALUES (450, 'ERD', 'Emenda de Redação', '');
INSERT INTO tipos_proposicao VALUES (451, 'PPR', 'Parecer Reformulado de Plenário', '');
INSERT INTO tipos_proposicao VALUES (452, 'TER', 'Termo de Implementação', NULL);
INSERT INTO tipos_proposicao VALUES (454, 'PDC', 'Projeto de Decreto Legislativo de Perempção da Concessão', '');
INSERT INTO tipos_proposicao VALUES (455, 'RLF', 'Relatório Final', '');
INSERT INTO tipos_proposicao VALUES (456, 'PRT', 'Parecer Técnico', '');
INSERT INTO tipos_proposicao VALUES (457, 'PRO', 'Proposta', '');
INSERT INTO tipos_proposicao VALUES (458, 'EXP', 'Exposição', '');
INSERT INTO tipos_proposicao VALUES (459, 'REC', 'Recurso contra decisão de presidente de Comissão em Reclamação (Art. 96, § 2º, RICD)', '');
INSERT INTO tipos_proposicao VALUES (460, 'OBJ', 'Objeto de Deliberação', '');
INSERT INTO tipos_proposicao VALUES (461, 'MSC', 'Mensagem de Missão de Paz (Art. 15 da LC 97/99)', 'Art. 15 da Lei Complementar nº 97/99');
INSERT INTO tipos_proposicao VALUES (462, '', 'I) OUTROS ITENS SUJEITOS À DELIBERAÇÃO', '');
INSERT INTO tipos_proposicao VALUES (463, '', 'G) PROPOSIÇÔES CN E SF TRAMITANDO NA CÂMARA (CMO E MERCOSUL)', '');
INSERT INTO tipos_proposicao VALUES (464, 'PLS', 'Projeto de Lei do Senado Federal', '');
INSERT INTO tipos_proposicao VALUES (465, 'PLC', 'Projeto de Lei da Câmara dos Deputados (SF)', '');
INSERT INTO tipos_proposicao VALUES (466, 'PDS', 'Projeto de Decreto Legislativo (SF)', '');
INSERT INTO tipos_proposicao VALUES (467, 'REQ', 'Requerimento de Adiamento de Votação em Regime de Urgência', 'Adiamento de Votação em Regime de Urgência, nos termos do art. 177, § 1º do RICD.');
INSERT INTO tipos_proposicao VALUES (468, 'REQ', 'Requerimento de Encerramento de discussão em Comissão', '');
INSERT INTO tipos_proposicao VALUES (481, 'ATOP', 'Ato do Presidente', '');
INSERT INTO tipos_proposicao VALUES (482, 'RDV', 'Redação do Vencido', '');
INSERT INTO tipos_proposicao VALUES (483, 'RST', 'Redação para o segundo turno', '');
INSERT INTO tipos_proposicao VALUES (484, 'RLP(R)', 'Relatório Prévio Reformulado', '');
INSERT INTO tipos_proposicao VALUES (485, 'PDC', 'Projeto de Decreto Legislativo de Aprovação de Contas dos Presidentes', '');
INSERT INTO tipos_proposicao VALUES (486, 'RQP', 'Requerimento de Plenário', '');
INSERT INTO tipos_proposicao VALUES (487, 'EPP', 'Emenda ao Plano Plurianual', 'Emenda ao Plano Plurianual');
INSERT INTO tipos_proposicao VALUES (488, 'EAG', 'Emenda Substitutiva Aglutinativa Global', '');
INSERT INTO tipos_proposicao VALUES (489, 'MSC', 'Mensagem que Propõe alteração a Projeto', '');
INSERT INTO tipos_proposicao VALUES (490, 'PEA', 'Parecer à Emenda Aglutinativa', '');
INSERT INTO tipos_proposicao VALUES (491, 'SPA', 'Sugestão de Emenda ao PPA - CLP', '');
INSERT INTO tipos_proposicao VALUES (492, 'TVR', 'Autorização - Rádio Comunitária - Dez anos', 'Autorização - Rádio Comunitária - Dez anos');
INSERT INTO tipos_proposicao VALUES (493, 'MSC', 'Mensagem de Perempção de Rádio/TV', '');
INSERT INTO tipos_proposicao VALUES (494, 'PDC', 'Projeto de Decreto Legislativo de Alteração de Decreto Legislativo', '');
INSERT INTO tipos_proposicao VALUES (495, 'AV', 'Aviso', '');
INSERT INTO tipos_proposicao VALUES (496, 'IAN', 'IAN', '');
INSERT INTO tipos_proposicao VALUES (497, 'OF.', 'Ofício Externo', '');
INSERT INTO tipos_proposicao VALUES (498, 'PCA', 'PCA', '');
INSERT INTO tipos_proposicao VALUES (499, 'PDA', 'PDA', '');
INSERT INTO tipos_proposicao VALUES (500, 'PDC', 'Projeto de Decreto Legislativo de Autorização do Congresso Nacional', '');
INSERT INTO tipos_proposicao VALUES (501, 'PRA', 'Projeto de Resolução da Assembleia Constituinte - 1987/88', '');
INSERT INTO tipos_proposicao VALUES (503, 'RCM', 'RCM', '');
INSERT INTO tipos_proposicao VALUES (504, 'RQA', 'Requerimento de Informações da Assembleia Constituinte - 1987/88', '');
INSERT INTO tipos_proposicao VALUES (505, 'RQC', 'RQC', NULL);
INSERT INTO tipos_proposicao VALUES (506, 'AA', 'Autógrafo', '');
INSERT INTO tipos_proposicao VALUES (507, 'REC', 'Recurso contra Inadmissibilidade de PEC (Art. 202, § 1º do RICD)', '');
INSERT INTO tipos_proposicao VALUES (508, 'ESP', 'Emenda Substitutiva de Plenário', '');
INSERT INTO tipos_proposicao VALUES (509, 'SSP', 'Subemenda Substitutiva de Plenário', '');
INSERT INTO tipos_proposicao VALUES (510, 'SAP', 'Subemenda Aglutinativa Substitutiva de Plenário', '');
INSERT INTO tipos_proposicao VALUES (513, 'MSC', 'Mensagem de Implementação da Lei 10.707/03', '');
INSERT INTO tipos_proposicao VALUES (514, 'PDC', 'Projeto de Decreto Legislativo de Ministro do TCU', '');
INSERT INTO tipos_proposicao VALUES (515, '', 'K) PROPOSIÇÕES INATIVAS IMPORTADAS SINOPSE', '');
INSERT INTO tipos_proposicao VALUES (516, 'REQ', 'Requerimento de Inclusão na Ordem do Dia de proposição (com previsão ou durante o período de Convocação Extraordinário)', '');
INSERT INTO tipos_proposicao VALUES (517, 'REQ', 'Requerimento de Interrupção da licença inferior a 120 dias', '');
INSERT INTO tipos_proposicao VALUES (518, 'REQ', 'Requerimento de Votação em globo da proposição', '');
INSERT INTO tipos_proposicao VALUES (519, 'REQ', 'Requerimento de Afastamento paramissão temporária de caráter diplomático ou cultural', '');
INSERT INTO tipos_proposicao VALUES (520, 'REQ', 'Requerimento de Constituição de Comissão Especial de Projeto de Código', '');
INSERT INTO tipos_proposicao VALUES (521, 'REQ', 'Requerimento de Constituição de Comissão Especial de Projeto', '');
INSERT INTO tipos_proposicao VALUES (522, 'REQ', 'Requerimento de Constituição de Comissão Especial de Estudo', '');
INSERT INTO tipos_proposicao VALUES (523, 'REQ', 'Requerimento de Convocação de Ministro de Estado na Comissão', '');
INSERT INTO tipos_proposicao VALUES (524, 'REQ', 'Requerimento de Convocação de Sessão Extraordinária', '');
INSERT INTO tipos_proposicao VALUES (525, 'REQ', 'Requerimento de Convocação de reunião extraordinária de comissão', '');
INSERT INTO tipos_proposicao VALUES (526, 'REQ', 'Requerimento de Destaque votação de emenda ou parte', '');
INSERT INTO tipos_proposicao VALUES (527, 'REQ', 'Requerimento de Destaque para votação de subemenda ou parte', '');
INSERT INTO tipos_proposicao VALUES (528, 'REQ', 'Requerimento de Destaque para tornar parte de emenda ou proposição projeto autonomo', '');
INSERT INTO tipos_proposicao VALUES (529, 'REQ', 'Requerimento de Destaque para votação de projeto ou substitutivo ou parte deles quando a preferencia cair sobre outro ou sobre proposições apensadas', '');
INSERT INTO tipos_proposicao VALUES (530, 'REQ', 'Requerimento de Destaque para votação de parte da proposição', '');
INSERT INTO tipos_proposicao VALUES (531, 'REQ', 'Requerimento de Prorrogação da sessão para discussão e votação da matéria da Ordem do Dia', '');
INSERT INTO tipos_proposicao VALUES (532, 'REQ', 'Requerimento de Prorrogação da sessão para audiência de Ministro de Estado', '');
INSERT INTO tipos_proposicao VALUES (533, 'REQ', 'Requerimento de Prorrogação da sessão para realização de homenagens', '');
INSERT INTO tipos_proposicao VALUES (534, 'REQ', 'Requerimento de Prorrogação de licença para tratamento de saúde (Licença inferior a 120 dias)', '');
INSERT INTO tipos_proposicao VALUES (535, 'MMP', 'Mensagem do Ministério Público da União', '');
INSERT INTO tipos_proposicao VALUES (536, 'RIN', 'Requerimento de Resolução Interna', '');
INSERT INTO tipos_proposicao VALUES (537, 'MST', 'Mensagem do Supremo Tribunal Federal', '');
INSERT INTO tipos_proposicao VALUES (538, 'APJ', 'Anteprojeto', '');
INSERT INTO tipos_proposicao VALUES (539, 'RQN', 'Requerimento do Congresso Nacional', 'Solicitação feita pela Claudia da SGM em 30/05/2005 as 18:14 (Incluído por MarcoRuas).
Requerimento do Congresso nacional que servirá de suporte aos recursos R.C (novos recursos). ');
INSERT INTO tipos_proposicao VALUES (540, 'R.C', 'Recurso do Congresso Nacional', 'Solicitação feita pela Claudia da SGM em 30/05/2005 as 18:14 (Incluído por MarcoRuas).
Os recursos existente em RCN serão transferidos para este novo código.');
INSERT INTO tipos_proposicao VALUES (541, 'MSC', 'Mensagem de Tranferência de Controle Societário', '');
INSERT INTO tipos_proposicao VALUES (542, 'SRAP', 'Sugestão de Requerimento de Audiência Pública', '');
INSERT INTO tipos_proposicao VALUES (600, 'CCN', 'Consulta do Congresso Nacional', 'Solicitação feita pela Claudia da SGM em 31/05/2005 as 14:30 (Incluído por MarceloLapa).
');
INSERT INTO tipos_proposicao VALUES (601, 'PDC', 'Projeto de Decreto Legislativo de Perempção', '');
INSERT INTO tipos_proposicao VALUES (602, 'MSC', 'Mensagem Revogação ou Anulação de Portaria', '');
INSERT INTO tipos_proposicao VALUES (603, 'ADD', 'Adendo', '');
INSERT INTO tipos_proposicao VALUES (604, 'DEC', 'Decisão', '');
INSERT INTO tipos_proposicao VALUES (605, 'ATC', 'Ato Convocatório', '');
INSERT INTO tipos_proposicao VALUES (606, 'PRST', 'Parecer à Redação para o Segundo Turno', '');
INSERT INTO tipos_proposicao VALUES (607, 'RLP(V)', 'Relatório Prévio Vencedor', '');
INSERT INTO tipos_proposicao VALUES (608, 'EMA', 'Emenda Aglutinativa de Plenário', '');
INSERT INTO tipos_proposicao VALUES (609, 'REQ', 'Requerimento de Criação de Frente Parlamentar', '');
INSERT INTO tipos_proposicao VALUES (610, 'DOC', 'Documentos internos', '');
INSERT INTO tipos_proposicao VALUES (611, 'SOR', 'Sugestão de Emenda ao Orçamento - Comissões', '');
INSERT INTO tipos_proposicao VALUES (612, 'SLD', 'Sugestão de Emenda à LDO - Comissões', '');
INSERT INTO tipos_proposicao VALUES (706, 'EMPV', 'Emenda a Medida Provisória', '');
INSERT INTO tipos_proposicao VALUES (613, 'SPP', 'Sugestão de Emenda ao PPA - Comissões', '');
INSERT INTO tipos_proposicao VALUES (614, 'RPA', 'Relatório Parcial', '');
INSERT INTO tipos_proposicao VALUES (615, 'MTC', 'Mensagem do Tribunal de Contas da União', '');
INSERT INTO tipos_proposicao VALUES (616, 'SPP-R', 'Sugestão de Emenda ao PPA - revisão (Comissões)', '');
INSERT INTO tipos_proposicao VALUES (617, 'SPA-R', 'Sugestão de Emenda ao PPA - revisão (CLP)', '');
INSERT INTO tipos_proposicao VALUES (618, 'REC', 'Recurso do Conselho de Ética que contraria norma constitucional ou regimental (Art. 14, VIII, CEDP)', '');
INSERT INTO tipos_proposicao VALUES (619, 'RFP', 'Refomulação de Parecer - art. 130, parágrafo único do RICD.', '');
INSERT INTO tipos_proposicao VALUES (620, 'PPP', 'Parecer Proferido em Plenário - Notas Taquigráficas', '');
INSERT INTO tipos_proposicao VALUES (621, 'PSS', 'Parecer às Emendas ou ao Substitutivo do Senado - Notas Taquigráficas', '');
INSERT INTO tipos_proposicao VALUES (622, 'PRVP', 'Proposta de Redação do Vencido em Primeiro Turno', '');
INSERT INTO tipos_proposicao VALUES (623, 'MSC', 'Mensagem de Afastamento/Interrupção de tratamento de saúde', '');
INSERT INTO tipos_proposicao VALUES (624, 'SUC', 'Sugestão a Projeto de Consolidação de Leis', '');
INSERT INTO tipos_proposicao VALUES (625, 'REQ', 'Requerimento de Prejudicialidade', '');
INSERT INTO tipos_proposicao VALUES (626, 'MSC', 'Mensagem de Cessão de Imóvel', '');
INSERT INTO tipos_proposicao VALUES (627, 'TVR', 'Perempção de Rádio/TV', '');
INSERT INTO tipos_proposicao VALUES (628, 'TVR', 'Revogação ou Anulação de Portaria de Rádio/TV', '');
INSERT INTO tipos_proposicao VALUES (629, 'TVR', 'Transferência de Controle Societário', '');
INSERT INTO tipos_proposicao VALUES (630, 'REC', 'Recurso contra indeferimento liminar de emenda à Medida Provisória (Art. 125, caput, RICD)', '');
INSERT INTO tipos_proposicao VALUES (631, 'REL', 'Relatório de Comissão Externa', '');
INSERT INTO tipos_proposicao VALUES (632, 'PLN', 'Projeto de Lei (CN)', '');
INSERT INTO tipos_proposicao VALUES (633, 'PLN', 'Projeto de Lei (CN) de Alteração do PPA e LDO', '');
INSERT INTO tipos_proposicao VALUES (634, 'PDN', 'Projeto de Decreto Legislativo (CN)', '');
INSERT INTO tipos_proposicao VALUES (635, 'AVN', 'Aviso (CN)', '');
INSERT INTO tipos_proposicao VALUES (636, 'AVN', 'Aviso (CN) de Relatório de Atividades do TCU', '');
INSERT INTO tipos_proposicao VALUES (637, 'AVN', 'Aviso (CN) de Relatório de Gestão Fiscal', '');
INSERT INTO tipos_proposicao VALUES (638, 'AVN', 'Aviso (CN) de Demonstrações Financeiras do Banco Central do Brasil', '');
INSERT INTO tipos_proposicao VALUES (639, 'AVN', 'Aviso (CN) de Contas do Governo da República', '');
INSERT INTO tipos_proposicao VALUES (640, 'AVN', 'Aviso (CN) de Relatório de Desempenho do Fundo Soberano do Brasil', '');
INSERT INTO tipos_proposicao VALUES (641, 'AVN', 'Aviso (CN) de Subtítulos com Indícios de Irregularidades Graves Apontadas pelo TCU', '');
INSERT INTO tipos_proposicao VALUES (642, 'AVN', 'Aviso (CN) de Operações de Redesconto e Empréstimo realizadas pelo Banco Central', '');
INSERT INTO tipos_proposicao VALUES (643, 'MCN', 'Mensagem (CN)', '');
INSERT INTO tipos_proposicao VALUES (644, 'OFN', 'Ofício (CN)', '');
INSERT INTO tipos_proposicao VALUES (645, 'MCN', 'Mensagem (CN) de Relatório de Avaliação do Cumprimento das Metas Fiscais/Superávit Primário, MCN', '');
INSERT INTO tipos_proposicao VALUES (646, 'MCN', 'Mensagem (CN) de Relatório de Gestão Fiscal, MCN', '');
INSERT INTO tipos_proposicao VALUES (647, 'MCN', 'Mensagem (CN) de Operações de Crédito Incluídas na LOA Pedentes de Contratação, MCN', '');
INSERT INTO tipos_proposicao VALUES (648, 'MCN', 'Mensagem (CN) de Relatório de Avaliação do PPA, MCN', '');
INSERT INTO tipos_proposicao VALUES (649, 'MCN', 'Mensagem (CN) de Contas do Governo da República, MCN', '');
INSERT INTO tipos_proposicao VALUES (650, 'MCN', 'Mensagem (CN) de Relatório de Avaliação de Receitas e Despesas, MCN', '');
INSERT INTO tipos_proposicao VALUES (651, 'OFN', 'Ofício (CN) de Relatório de Gestão Fiscal', '');
INSERT INTO tipos_proposicao VALUES (652, 'OFN', 'Ofício (CN) de Relatório Trimestral Gerencial do BNDES', '');
INSERT INTO tipos_proposicao VALUES (653, 'OFN', 'Ofício (CN) de Operações de Empréstimo de Capital de Giro Contratadas pela Caixa Econômica Federal', '');
INSERT INTO tipos_proposicao VALUES (654, 'OFN', 'Ofício (CN) de Demonstrações Contábeis de Fundo Constitucional de Financiamento', '');
INSERT INTO tipos_proposicao VALUES (655, 'OFN', 'Ofício (CN) de Contas do Governo da República', '');
INSERT INTO tipos_proposicao VALUES (656, 'OFN', 'Ofício (CN) de Subtítulos com Indícios de Irregularidades Graves apontadas pelo TCU', '');
INSERT INTO tipos_proposicao VALUES (657, 'PLN', 'Projeto de Lei (CN) de Crédito Especial', '');
INSERT INTO tipos_proposicao VALUES (658, 'PLN', 'Projeto de Lei (CN) de Crédito Suplementar', '');
INSERT INTO tipos_proposicao VALUES (659, 'PLN', 'Projeto de Lei (CN) de Lei Orçamentária Anual (LOA)', '');
INSERT INTO tipos_proposicao VALUES (660, 'PLN', 'Projeto de Lei (CN) de Lei de Diretrizes Orçamentárias (LDO)', '');
INSERT INTO tipos_proposicao VALUES (661, 'PLN', 'Projeto de Lei (CN) de Plano Plurianual', '');
INSERT INTO tipos_proposicao VALUES (662, 'MSF', 'Mensagem (SF)', '');
INSERT INTO tipos_proposicao VALUES (663, 'PRP', 'Parecer do Relator Parcial', '');
INSERT INTO tipos_proposicao VALUES (664, 'REQ', 'Requerimento de Retirada de Emenda a Medida Provisória', '');
INSERT INTO tipos_proposicao VALUES (665, 'EMRP', 'Emenda de Relator Parcial', '');
INSERT INTO tipos_proposicao VALUES (666, 'CAC', 'Comunicado de alteração do controle societário', '');
INSERT INTO tipos_proposicao VALUES (667, 'RRL', 'Relatório do Relator', '');
INSERT INTO tipos_proposicao VALUES (668, 'CVR', 'Contestação ao Voto do Relator', '');
INSERT INTO tipos_proposicao VALUES (669, 'PARF', 'Parecer de Comissão para Redação Final', '');
INSERT INTO tipos_proposicao VALUES (670, 'MPV', 'Medida Provisória de Crédito Extraordinário', '');
INSERT INTO tipos_proposicao VALUES (671, 'OFN', 'Ofício (CN) de Relatório de Atividades da Autoridade Pública Olímpica - APO', '');
INSERT INTO tipos_proposicao VALUES (672, 'AVN', 'Aviso (CN) de Relatório de Gestão Fiscal do Tribunal de Contas da União', '');
INSERT INTO tipos_proposicao VALUES (673, 'OFN', 'Ofício (CN) de Lei de Incentivo ao Esporte', '');
INSERT INTO tipos_proposicao VALUES (674, 'SRL', 'Sugestão de Emenda a Relatório', '');
INSERT INTO tipos_proposicao VALUES (675, 'RPL', 'Relatório Preliminar', '');
INSERT INTO tipos_proposicao VALUES (676, 'RRC', 'Relatório de Receita', '');
INSERT INTO tipos_proposicao VALUES (679, 'RPLE', 'Relatório Preliminar Apresentado com Emendas', '');
INSERT INTO tipos_proposicao VALUES (680, 'ERR', 'Errata', '');
INSERT INTO tipos_proposicao VALUES (681, 'CAE', 'Relatório de Atividades do Comitê de Admissibilidade de Emendas (CAE)', '');
INSERT INTO tipos_proposicao VALUES (682, 'COI', 'Relatório do COI', '');
INSERT INTO tipos_proposicao VALUES (683, 'RAT', 'Relatório Setorial', '');
INSERT INTO tipos_proposicao VALUES (685, 'CAE', 'Relatório', '');
INSERT INTO tipos_proposicao VALUES (686, 'REQ', 'Requerimento de Participação ou Realização de Eventos fora da Câmara', '');
INSERT INTO tipos_proposicao VALUES (687, 'REQ', 'Requerimento de Reapresentação de Projeto de Lei Rejeitado na mesma Sessão Legislativa', '');
INSERT INTO tipos_proposicao VALUES (688, 'REQ', 'Requerimento de Inclusão de Matéria Extra-Pauta na Ordem do Dia das Comissões', '');
INSERT INTO tipos_proposicao VALUES (689, 'OFN', 'Ofício (CN) de Informações de Execução das Obras do PAC', '');
INSERT INTO tipos_proposicao VALUES (690, 'OFS', 'Ofício do Senado Federal', '');
INSERT INTO tipos_proposicao VALUES (691, 'OFS', 'Ofício do Senado Federal de Fundo Constitucional de Financiamento', '');
INSERT INTO tipos_proposicao VALUES (692, 'PLN', 'Projeto de Lei (CN) de Alteração da LDO', '');
INSERT INTO tipos_proposicao VALUES (693, 'PLN', 'Projeto de Lei (CN) de Alteração da LOA', '');
INSERT INTO tipos_proposicao VALUES (694, 'MSG', 'Mensagem (CN)', '');
INSERT INTO tipos_proposicao VALUES (695, 'MSG', 'Mensagem (CN) de Contas do Governo da República', '');
INSERT INTO tipos_proposicao VALUES (696, 'OFN', 'Ofício (CN) de Demonstrações Contábeis do Fundo Constitucional de Financiamento do Norte (FNO)', '');
INSERT INTO tipos_proposicao VALUES (697, 'OFN', 'Ofício (CN) de Demonstrações Contábeis do Fundo Constitucional de Financiamento do Centro-Oeste (FCO)', '');
INSERT INTO tipos_proposicao VALUES (698, 'OFN', 'Ofício (CN) de Demonstrações Contábeis do Fundo Constitucional de Financiamento do Nordeste (FNE).', '');
INSERT INTO tipos_proposicao VALUES (699, 'PLN', 'Projeto de Lei (CN) de Alteração do PPA', '');
INSERT INTO tipos_proposicao VALUES (700, '', 'Outras Proposições - Comissão Mista', '');
INSERT INTO tipos_proposicao VALUES (701, 'SBT-A', 'Substitutivo adotado pela Comissão', '');
INSERT INTO tipos_proposicao VALUES (702, 'EMC-A', 'Emenda Adotada pela Comissão', '');
INSERT INTO tipos_proposicao VALUES (703, 'SBE-A', 'Subemenda Adotada pela Comissão', '');
INSERT INTO tipos_proposicao VALUES (704, 'RPLOA', 'Relatório Preliminar', '');
INSERT INTO tipos_proposicao VALUES (705, 'ANEXO', 'Anexo', '');
INSERT INTO tipos_proposicao VALUES (707, 'REL', 'Relatório do Congresso Nacional', '');
INSERT INTO tipos_proposicao VALUES (708, 'OF', 'Ofício do Congresso Nacional', '');
INSERT INTO tipos_proposicao VALUES (709, 'SBR', 'Subemenda de Relator', '');
INSERT INTO tipos_proposicao VALUES (710, 'AVN', 'Aviso (CN) de Contas do Gestor Federal do SUS', '');
INSERT INTO tipos_proposicao VALUES (711, 'OFN', 'Ofício (CN) de Demonstrações Financeiras do Banco Central do Brasil', '');
INSERT INTO tipos_proposicao VALUES (712, 'AVN', 'Aviso (CN) de Contas do TCU', '');
INSERT INTO tipos_proposicao VALUES (713, 'ERD-A', 'Emenda de Redação Adotada', '');
INSERT INTO tipos_proposicao VALUES (714, 'PIN', 'Proposta de Instrução Normativa', '');
INSERT INTO tipos_proposicao VALUES (715, 'OFN', 'Ofício (CN) de Contas do TCU', '');
INSERT INTO tipos_proposicao VALUES (810, 'ATA', 'Ata', '');
INSERT INTO tipos_proposicao VALUES (814, 'CRVITAEDOC', 'Curriculum Vitae/Outro Documento', NULL);
INSERT INTO tipos_proposicao VALUES (822, 'OF', 'Ofício do Congresso Nacional', NULL);
INSERT INTO tipos_proposicao VALUES (823, 'OF', 'Ofício do Senado Federal', NULL);
INSERT INTO tipos_proposicao VALUES (830, 'PR/CNMP', 'Parecer do Conselho Nacional do Ministério Público', NULL);
INSERT INTO tipos_proposicao VALUES (831, 'PR/CNJ', 'Parecer do Conselho Nacional de Justiça', NULL);
INSERT INTO tipos_proposicao VALUES (832, 'OFN', 'Ofício (CN) de Relatório Anual da Agência Nacional de Transportes Aquaviários - Antaq', '');
INSERT INTO tipos_proposicao VALUES (833, '', 'L) DOCUMENTOS DE CPI', '');
INSERT INTO tipos_proposicao VALUES (834, 'DOCCPI', 'Documento de CPI ostensivo', '');
INSERT INTO tipos_proposicao VALUES (835, 'DOCCPI', 'Documento de CPI sigiloso', '');
INSERT INTO tipos_proposicao VALUES (836, 'OFJ', 'Ofício de órgão do Poder Judiciário', NULL);
INSERT INTO tipos_proposicao VALUES (837, 'OFE', 'Ofício de órgão do Poder Executivo', NULL);
INSERT INTO tipos_proposicao VALUES (838, 'MAD', 'Manifestação do(a) Denunciado(a)', '');
INSERT INTO tipos_proposicao VALUES (839, 'PDC', 'Projeto de Decreto Legislativo sobre Declaração de Guerra e correlatos', '');
INSERT INTO tipos_proposicao VALUES (840, 'PDC', 'Projeto de Decreto Legislativo sobre Estado de Defesa, Estado de Sítio e Intervenção Federal nos Estados', '');
INSERT INTO tipos_proposicao VALUES (841, 'PDC', 'Projeto de Decreto Legislativo sobre transferência temporária da sede do Governo Federal', '');
INSERT INTO tipos_proposicao VALUES (842, 'PDC', 'Projeto de Decreto Legislativo para autorizar o Presidente ou o Vice-Presidente da República a se ausentarem do paíse, por mais de 15 dias (art. 49, II, CF)', '');
INSERT INTO tipos_proposicao VALUES (843, 'SIP', 'Solicitação para instauração de processo', 'Artigo 217 do RICD');
INSERT INTO tipos_proposicao VALUES (844, 'REC', 'Recurso contra aplicação de censura escrita (Art. 12, § 2º do CEDP)', 'Contra aplicação de censura escrita (Art. 12, § 2º do CEDP)');


--
-- Name: tipos_proposicao_id_tipo_proposicao_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('tipos_proposicao_id_tipo_proposicao_seq', 1, false);


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO usuarios VALUES (1, 'Diego Oliveira', '1991-02-28', 'diegol@gmail.com', '123456');
INSERT INTO usuarios VALUES (2, 'Maria Luiza', '1990-12-05', 'maria@gmail.com', '654321');


--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('usuarios_id_usuario_seq', 2, true);


--
-- Data for Name: votos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: blocos blocos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY blocos
    ADD CONSTRAINT blocos_pkey PRIMARY KEY (id_bloco);


--
-- Name: deputados deputados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deputados
    ADD CONSTRAINT deputados_pkey PRIMARY KEY (id_deputado);


--
-- Name: despesas despesas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY despesas
    ADD CONSTRAINT despesas_pkey PRIMARY KEY (id_despesa);


--
-- Name: gabinetes gabinetes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gabinetes
    ADD CONSTRAINT gabinetes_pkey PRIMARY KEY (id_gabinete);


--
-- Name: legislaturas legislaturas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY legislaturas
    ADD CONSTRAINT legislaturas_pkey PRIMARY KEY (id_legislatura);


--
-- Name: partidos partidos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY partidos
    ADD CONSTRAINT partidos_pkey PRIMARY KEY (id_partido);


--
-- Name: partidos partidos_sigla_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY partidos
    ADD CONSTRAINT partidos_sigla_key UNIQUE (sigla);


--
-- Name: proposicoes proposicoes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY proposicoes
    ADD CONSTRAINT proposicoes_pkey PRIMARY KEY (id_proposicao);


--
-- Name: tipos_proposicao tipos_proposicao_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tipos_proposicao
    ADD CONSTRAINT tipos_proposicao_pkey PRIMARY KEY (id_tipo_proposicao);


--
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: despesas despesas_gatilho; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER despesas_gatilho BEFORE INSERT OR UPDATE ON despesas FOR EACH ROW EXECUTE PROCEDURE testa_valor();


--
-- Name: legislaturas legislaturas_gatilho; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER legislaturas_gatilho BEFORE INSERT OR UPDATE ON legislaturas FOR EACH ROW EXECUTE PROCEDURE testa_duracao();


--
-- Name: deputados deputados_id_gabinete_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deputados
    ADD CONSTRAINT deputados_id_gabinete_fkey FOREIGN KEY (id_gabinete) REFERENCES gabinetes(id_gabinete);


--
-- Name: deputados deputados_id_partido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deputados
    ADD CONSTRAINT deputados_id_partido_fkey FOREIGN KEY (id_partido) REFERENCES partidos(sigla);


--
-- Name: deputados_proposicoes deputados_proposicoes_id_deputado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deputados_proposicoes
    ADD CONSTRAINT deputados_proposicoes_id_deputado_fkey FOREIGN KEY (id_deputado) REFERENCES deputados(id_deputado);


--
-- Name: deputados_proposicoes deputados_proposicoes_id_proposicao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deputados_proposicoes
    ADD CONSTRAINT deputados_proposicoes_id_proposicao_fkey FOREIGN KEY (id_proposicao) REFERENCES proposicoes(id_proposicao);


--
-- Name: despesas despesas_id_deputado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY despesas
    ADD CONSTRAINT despesas_id_deputado_fkey FOREIGN KEY (id_deputado) REFERENCES deputados(id_deputado);


--
-- Name: inscricoes inscricoes_id_deputado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inscricoes
    ADD CONSTRAINT inscricoes_id_deputado_fkey FOREIGN KEY (id_deputado) REFERENCES deputados(id_deputado);


--
-- Name: inscricoes inscricoes_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY inscricoes
    ADD CONSTRAINT inscricoes_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES usuarios(id_usuario);


--
-- Name: mandatos mandatos_id_deputado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mandatos
    ADD CONSTRAINT mandatos_id_deputado_fkey FOREIGN KEY (id_deputado) REFERENCES deputados(id_deputado);


--
-- Name: mandatos mandatos_id_legislatura_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mandatos
    ADD CONSTRAINT mandatos_id_legislatura_fkey FOREIGN KEY (id_legislatura) REFERENCES legislaturas(id_legislatura);


--
-- Name: proposicoes proposicoes_id_tipo_proposicao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY proposicoes
    ADD CONSTRAINT proposicoes_id_tipo_proposicao_fkey FOREIGN KEY (id_tipo_proposicao) REFERENCES tipos_proposicao(id_tipo_proposicao);


--
-- Name: votos votos_id_deputado_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY votos
    ADD CONSTRAINT votos_id_deputado_fkey FOREIGN KEY (id_deputado) REFERENCES deputados(id_deputado);


--
-- Name: votos votos_id_proposicao_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY votos
    ADD CONSTRAINT votos_id_proposicao_fkey FOREIGN KEY (id_proposicao) REFERENCES proposicoes(id_proposicao);


--
-- PostgreSQL database dump complete
--

