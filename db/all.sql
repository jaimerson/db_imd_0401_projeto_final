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
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = public, pg_catalog;

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
    RAISE EXCEPTION 'Duração de uma legislatura não pode ser maior que 4 anos.';
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
    sexo character(1) NOT NULL,
    url_website character varying(128) NOT NULL,
    situacao character varying(64) NOT NULL,
    data_nascimento date NOT NULL,
    escolaridade character varying(64),
    id_partido integer NOT NULL,
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
    ano date NOT NULL,
    cnpj_cpf_fornecedor character varying(24) NOT NULL,
    data_documento date NOT NULL,
    tipo_documento character varying(24) NOT NULL,
    mes integer NOT NULL,
    nome_fornecedor character varying(24) NOT NULL,
    num_documento integer NOT NULL,
    num_ressarcimento integer NOT NULL,
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
-- Name: gabinete; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gabinete (
    id_gabinete integer NOT NULL,
    nome character varying(255) NOT NULL,
    predio integer NOT NULL,
    sala integer NOT NULL,
    andar integer NOT NULL,
    telefone character varying(16) NOT NULL,
    email character varying(24) NOT NULL
);


--
-- Name: gabinete_id_gabinete_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE gabinete_id_gabinete_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: gabinete_id_gabinete_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE gabinete_id_gabinete_seq OWNED BY gabinete.id_gabinete;


--
-- Name: gabinetes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE gabinetes (
    id_gabinete integer NOT NULL,
    nome character varying(255) NOT NULL,
    predio integer NOT NULL,
    sala integer NOT NULL,
    andar integer NOT NULL,
    telefone character varying(16) NOT NULL,
    email character varying(24) NOT NULL
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
    numero integer NOT NULL,
    ano integer NOT NULL,
    ementa text NOT NULL,
    data_apresentacao date NOT NULL,
    status jsonb NOT NULL,
    tipo_autor character varying(100) NOT NULL,
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
-- Name: gabinete id_gabinete; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY gabinete ALTER COLUMN id_gabinete SET DEFAULT nextval('gabinete_id_gabinete_seq'::regclass);


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



--
-- Name: despesas_id_despesa_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('despesas_id_despesa_seq', 1, false);


--
-- Data for Name: gabinete; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: gabinete_id_gabinete_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gabinete_id_gabinete_seq', 1, false);


--
-- Data for Name: gabinetes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: gabinetes_id_gabinete_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('gabinetes_id_gabinete_seq', 1, false);


--
-- Data for Name: inscricoes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: legislaturas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: legislaturas_id_legislatura_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('legislaturas_id_legislatura_seq', 1, false);


--
-- Data for Name: mandatos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: partidos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: partidos_id_partido_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('partidos_id_partido_seq', 1, false);


--
-- Data for Name: proposicoes; Type: TABLE DATA; Schema: public; Owner: -
--



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



--
-- Name: usuarios_id_usuario_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('usuarios_id_usuario_seq', 1, false);


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
-- Name: gabinete gabinete_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY gabinete
    ADD CONSTRAINT gabinete_pkey PRIMARY KEY (id_gabinete);


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
    ADD CONSTRAINT deputados_id_gabinete_fkey FOREIGN KEY (id_gabinete) REFERENCES gabinete(id_gabinete);


--
-- Name: deputados deputados_id_partido_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY deputados
    ADD CONSTRAINT deputados_id_partido_fkey FOREIGN KEY (id_partido) REFERENCES partidos(id_partido);


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

