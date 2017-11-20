/* DDL */
/* Tabelas principais */
CREATE TABLE usuarios (
  id_usuario SERIAL PRIMARY KEY,
  nome VARCHAR(255) NOT NULL,
  data_nascimento DATE NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  /* salvar como md5('original_password') */
  password_digest TEXT NOT NULL
);

CREATE TABLE legislaturas (
  id_legislatura SERIAL PRIMARY KEY,
  data_inicio DATE NOT NULL CONSTRAINT data_inicio_maior CHECK (data_inicio < data_fim),
  data_fim DATE NOT NULL CONSTRAINT data_fim_menor CHECK (data_fim > data_inicio)
);

CREATE TABLE tipos_proposicao (
  id_tipo_proposicao SERIAL PRIMARY KEY,
  sigla VARCHAR(20) NOT NULL,
  nome VARCHAR(255) NOT NULL,
  descricao TEXT
);

CREATE TABLE proposicoes (
  id_proposicao SERIAL PRIMARY KEY,
  id_tipo_proposicao INTEGER REFERENCES tipos_proposicao(id_tipo_proposicao) NOT NULL,
  numero INTEGER,
  ano INTEGER CONSTRAINT year CHECK (ano BETWEEN 1000 AND 9999),
  ementa TEXT,
  data_apresentacao DATE,
  situacao VARCHAR(500),
  tipo_autor VARCHAR(100),
  ementa_detalhada TEXT,
  texto TEXT,
  justificativa TEXT,
  keywords VARCHAR(500)
);

CREATE TABLE blocos (
  id_bloco SERIAL PRIMARY KEY,
  nome VARCHAR(100) NOT NULL
);

CREATE TABLE partidos (
  id_partido SERIAL PRIMARY KEY,
  nome VARCHAR(255) NOT NULL,
  sigla VARCHAR(10) NOT NULL UNIQUE
);

CREATE TABLE gabinetes (
  id_gabinete SERIAL PRIMARY KEY,
  nome VARCHAR(255) NOT NULL,
  predio VARCHAR(30),
  sala VARCHAR(30),
  andar VARCHAR(30),
  telefone VARCHAR(16),
  email VARCHAR(100)
);

CREATE TABLE deputados (
  id_deputado SERIAL PRIMARY KEY,
  nome_civil VARCHAR(255) NOT NULL,
  nome VARCHAR(255) NOT NULL,
  cpf VARCHAR(15) NOT NULL,
  sexo CHAR(1),
  url_website VARCHAR(128),
  situacao VARCHAR(64),
  data_nascimento DATE,
  escolaridade VARCHAR(64),
  id_partido VARCHAR(10) REFERENCES partidos(sigla) NOT NULL,
  id_gabinete INTEGER REFERENCES gabinetes(id_gabinete) NOT NULL
);

CREATE TABLE despesas (
  id_despesa SERIAL PRIMARY KEY,
  ano VARCHAR(4) NOT NULL,
  cnpj_cpf_fornecedor VARCHAR(100) NOT NULL,
  data_documento DATE NOT NULL,
  tipo_documento VARCHAR(100) NOT NULL,
  mes VARCHAR(3) NOT NULL,
  nome_fornecedor VARCHAR(100) NOT NULL,
  num_documento VARCHAR(40) NOT NULL,
  num_ressarcimento VARCHAR(40) NOT NULL,
  parcela INTEGER NOT NULL,
  tipo_despesa VARCHAR(64) NOT NULL,
  url_documento VARCHAR(64) NOT NULL,
  valor_documento FLOAT NOT NULL,
  valor_glosa FLOAT NOT NULL,
  valor_liquido FLOAT NOT NULL,
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL
);

/* Tabelas auxiliares */
CREATE TABLE mandatos (
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL,
  id_legislatura INTEGER REFERENCES legislaturas(id_legislatura) NOT NULL
);

CREATE TABLE deputados_proposicoes (
  id_proposicao INTEGER REFERENCES proposicoes(id_proposicao) NOT NULL,
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL
);

CREATE TABLE votos (
  id_proposicao INTEGER REFERENCES proposicoes(id_proposicao) NOT NULL,
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL,
  voto VARCHAR(8) NOT NULL
);

CREATE TABLE inscricoes (
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL,
  id_usuario INTEGER REFERENCES usuarios(id_usuario) NOT NULL
);

/* Funções & Gatilhos */
CREATE FUNCTION testa_valor() RETURNS TRIGGER as $despesas_gatilho$
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
$despesas_gatilho$ LANGUAGE plpgsql;

CREATE TRIGGER despesas_gatilho BEFORE INSERT OR UPDATE
ON despesas
FOR EACH ROW EXECUTE
PROCEDURE testa_valor();

CREATE FUNCTION testa_duracao() RETURNS TRIGGER as $legislaturas_gatilho$
BEGIN
  -- Verifica valor minimo do documento
  IF ((DATE_PART('year', NEW.data_fim::date) - DATE_PART('year', NEW.data_inicio::date)) * 12 +
    (DATE_PART('month', NEW.data_fim::date) - DATE_PART('month', NEW.data_inicio::date)))  > 48 THEN
    RAISE EXCEPTION 'Duração de uma legislatura não pode ser maior que 4 anos.';
  END IF;

  RETURN NEW;
END;
$legislaturas_gatilho$ LANGUAGE plpgsql;

CREATE TRIGGER legislaturas_gatilho BEFORE INSERT OR UPDATE
ON legislaturas
FOR EACH ROW EXECUTE
PROCEDURE testa_duracao();
