/* Tabelas principais */
CREATE TABLE usuarios (
  id_usuario SERIAL,
  nome VARCHAR(255) NOT NULL,
  data_nascimento DATE NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  /* salvar como md5('original_password') */
  password_digest TEXT NOT NULL
)

CREATE TABLE legislaturas (
  id_legislatura INTEGER PRIMARY KEY DEFAULT nextval('serial'),
  data_inicio DATE NOT NULL,
  data_fim DATE NOT NULL
)

CREATE TABLE tipos_proposicao (
  id_tipo_proposicao INTEGER PRIMARY_KEY,
  sigla VARCHAR(20) NOT NULL,
  nome VARCHAR(255) NOT NULL,
  descricao TEXT NOT NULL
)

CREATE TABLE proposicoes (
  id_proposicao INTEGER PRIMARY KEY DEFAULT nextval('serial'),
  id_tipo_proposicao INTEGER REFERENCES tipos_proposicao(id_tipo_proposicao) NOT NULL,
  numero INTEGER NOT NULL,
  ano INTEGER CONSTRAINT year CHECK ano BETWEEN 1000 AND 9999 NOT NULL,
  ementa TEXT NOT NULL,
  data_apresentacao DATE NOT NULL,
  status JSONB NOT NULL,
  tipo_autor VARCHAR(100) NOT NULL,
  ementa_detalhada TEXT,
  texto TEXT,
  justificativa TEXT
  keywords VARCHAR(500) NOT NULL,
)

CREATE TABLE blocos (
  id_bloco INTEGER PRIMARY KEY DEFAULT nextval('serial'),
  nome VARCHAR(100) NOT NULL
)

CREATE TABLE partidos (
  id_partido INTEGER PRIMARY KEY DEFAULT nextval('serial'),
  nome VARCHAR(255) NOT NULL,
  sigla VARCHAR(10) NOT NULL,
  situacao VARCHAR(20) NOT NULL,
  id_bloco INTEGER REFERENCES blocos(id_bloco) NOT NULL
)

CREATE TABLE gabinete (
  id_gabinete INTEGER PRIMARY KEY DEFAULT nextval('serial'),
  nome VARCHAR(255) NOT NULL,
  predio INTEGER NOT NULL,
  sala INTEGER NOT NULL,
  andar INTEGER NOT NULL,
  telefone VARCHAR(16) NOT NULL,
  email VARCHAR(24) NOT NULL
)

CREATE TABLE deputados (
  id_deputado INTEGER PRIMARY KEY DEFAULT nextval('serial'),
  nome_civil VARCHAR(255) NOT NULL,
  nome VARCHAR(255) NOT NULL,
  cpf VARCHAR(15) NOT NULL,
  sexo CHAR(1) NOT NULL,
  url_website VARCHAR(128) NOT NULL,
  situacao VARCHAR(64) NOT NULL,
  data_nascimento DATE NOT NULL,
  escolaridade VARCHAR(64) NOT NULL,
  id_partido INTEGER REFERENCES partidos(id_partido) NOT NULL,
  id_gabinete INTEGER REFERENCES gabinete(id_gabinete) NOT NULL
)

CREATE TABLE despesas (
  id_despesa INTEGER PRIMARY KEY DEFAULT nextval('serial'),
  ano DATE NOT NULL,
  cnpj_cpf_fornecedor VARCHAR(24) NOT NULL,
  data_documento DATE NOT NULL,
  tipo_documento VARCHAR(24) NOT NULL,
  mes INTEGER NOT NULL,
  nome_fornecedor VARCHAR(24) NOT NULL,
  num_documento INTEGER NOT NULL,
  num_ressarcimento INTEGER NOT NULL,
  parcela INTEGER NOT NULL,
  tipo_despesa VARCHAR(64) NOT NULL,
  tipo_documento VARCHAR(64) NOT NULL,
  url_documento VARCHAR(64) NOT NULL,
  valor_documento FLOAT NOT NULL,
  valor_glosa FLOAT NOT NULL,
  valor_liquido FLOAT NOT NULL,
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL,
)

/* Tabelas auxiliares */
CREATE TABLE mandatos (
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL,
  id_legislatura INTEGER REFERENCES legislaturas(id_legislatura) NOT NULL
)

CREATE TABLE autores (
  id_proposicao INTEGER REFERENCES proposicoes(id_proposicao) NOT NULL,
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL
)

CREATE TABLE votos (
  id_proposicao INTEGER REFERENCES gabinete(id_proposicao) NOT NULL,
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL,
  voto VARCHAR(8) NOT NULL
)

CREATE TABLE inscricoes (
  id_deputado INTEGER REFERENCES deputados(id_deputado) NOT NULL,
  id_usuario INTEGER REFERENCES usuarios(id_usuario) NOT NULL,
  id_mandato INTEGER REFERENCES mandatos(id_mandato) NOT NULL,
)
