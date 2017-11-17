CREATE TABLE usuarios (
  id_usuario SERIAL,
  nome VARCHAR(255) NOT NULL,
  data_nascimento DATE NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  /* salvar como md5('original_password') */
  password_digest TEXT NOT NULL
);

CREATE TABLE legislaturas (
  id_legislatura INTEGER PRIMARY KEY,
  data_inicio DATE NOT NULL,
  data_fim DATE NOT NULL
);

CREATE TABLE tipos_proposicao (
  id_tipo_proposicao INTEGER PRIMARY KEY,
  sigla VARCHAR(20) NOT NULL,
  nome VARCHAR(255) NOT NULL,
  descricao TEXT NOT NULL
);

CREATE TABLE proposicoes (
  id_proposicao INTEGER PRIMARY KEY,
  id_tipo_proposicao INTEGER REFERENCES tipos_proposicao(id_tipo_proposicao) NOT NULL,
  numero INTEGER NOT NULL,
  ano INTEGER CONSTRAINT year CHECK(ano BETWEEN 1000 AND 9999) NOT NULL,
  ementa TEXT NOT NULL,
  data_apresentacao DATE NOT NULL,
  status JSONB NOT NULL,
  tipo_autor VARCHAR(100) NOT NULL,
  descricao_tipo VARCHAR(100) NOT NULL,
  ementa_detalhada TEXT,
  texto TEXT,
  justificativa TEXT
);

CREATE TABLE blocos (
  id_bloco INTEGER PRIMARY KEY,
  nome VARCHAR(100) NOT NULL
);

CREATE TABLE partidos (
  id_partido INTEGER PRIMARY KEY,
  nome VARCHAR(255) NOT NULL,
  sigla VARCHAR(10) NOT NULL,
  situacao VARCHAR(20) NOT NULL,
  id_bloco INTEGER REFERENCES blocos(id_bloco) NOT NULL
);
