-- importa tipos_proposicao
BEGIN TRANSACTION;

CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'referencias', 'tiposProposicao.json')) %>'
CSV quote e'\x01' delimiter e'\x02';

-- edit the <%# ... %> for the absolute path if needed

INSERT INTO tipos_proposicao (id_tipo_proposicao, sigla, nome, descricao)
SELECT (values->>'id')::int AS id_tipo_proposicao,
       values->>'sigla',
       values->>'nome',
       values->>'descricao'
FROM (
  SELECT json_array_elements(values::json) AS values
  FROM temp_json
) elements;

END TRANSACTION;
-- importa tipos_proposicao

-- importa blocos
BEGIN TRANSACTION;

CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'blocos.json')) %>'
CSV quote e'\x01' delimiter e'\x02';

-- edit the <%# ... %> for the absolute path if needed

INSERT INTO blocos (id_bloco, nome)
SELECT (values->>'id')::int AS id_bloco,
        values->>'nome'
FROM (
  SELECT json_array_elements(values::json) AS values
  FROM temp_json
) elements;

END TRANSACTION;
-- importa blocos

-- importa legislaturas
BEGIN TRANSACTION;

CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'legislaturas.json')) %>'
CSV quote e'\x01' delimiter e'\x02';

-- edit the <%# ... %> for the absolute path if needed

INSERT INTO legislaturas (id_legislatura, data_inicio, data_fim)
SELECT (values->>'id')::int AS id_legislatura,
       (values->>'dataInicio')::date AS data_inicio,
       (values->>'dataFim')::date AS data_fim
FROM (
  SELECT json_array_elements(values::json) AS values
  FROM temp_json
) elements;

END TRANSACTION;
-- importa legislaturas

-- importa partidos
BEGIN TRANSACTION;

CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'partidos.json')) %>'
CSV quote e'\x01' delimiter e'\x02';

-- edit the <%# ... %> for the absolute path if needed

INSERT INTO partidos (id_partido, sigla, nome)
SELECT (values->>'id')::int AS id_partido,
       values->>'sigla',
       values->>'nome'
FROM (
  SELECT json_array_elements(values::json) AS values
  FROM temp_json
) elements;

END TRANSACTION;
-- importa partidos

-- importa deputados & gabinetes
BEGIN TRANSACTION;

CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'detalhes_deputados.json')) %>'
CSV quote e'\x01' delimiter e'\x02';

-- edit the <%# ... %> for the absolute path if needed

-- popular gabinetes
INSERT INTO gabinetes (id_gabinete, nome, predio, sala, andar, telefone, email)
SELECT (values->>'id')::int AS id_gabinete,
       values->'ultimoStatus'->'gabinete'->>'nome',
       values->'ultimoStatus'->'gabinete'->>'predio',
       values->'ultimoStatus'->'gabinete'->>'sala',
       values->'ultimoStatus'->'gabinete'->>'andar',
       values->'ultimoStatus'->'gabinete'->>'telefone',
       values->'ultimoStatus'->'gabinete'->>'email'
FROM (
 SELECT json_array_elements(values::json) AS values
 FROM temp_json
) elements;

INSERT INTO deputados (id_deputado, nome_civil, nome, cpf, sexo, url_website,
situacao, data_nascimento, escolaridade, id_partido, id_gabinete)
SELECT (values->>'id')::int AS id_deputado,
       (values->>'nomeCivil')::varchar AS nome_civil,
       values->'ultimoStatus'->>'nome',
       values->>'cpf',
       values->>'sexo',
       (values->>'urlWebsite')::varchar AS url_website,
       values->'ultimoStatus'->>'situacao',
       (values->>'dataNascimento')::date AS data_nascimento,
       values->>'escolaridade',
       values->'ultimoStatus'->>'siglaPartido',
       (values->>'id')::int
FROM (
  SELECT json_array_elements(values::json) AS values
  FROM temp_json
) elements;


END TRANSACTION;
-- importa deputados & gabinetes

-- importa despesas
BEGIN TRANSACTION;
  SELECT add_deputado_by_file();
END TRANSACTION;
-- importa despesas

-- importa proposicoes
BEGIN TRANSACTION;

CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'proposicoes.json')) %>'
CSV quote e'\x01' delimiter e'\x02';

-- edit the <%# ... %> for the absolute path if needed

INSERT INTO proposicoes (id_proposicao, id_tipo_proposicao, numero, ano, ementa,
data_apresentacao, situacao, tipo_autor, ementa_detalhada, texto, justificativa, keywords)
SELECT (values->>'id')::int AS id_proposicao,
        (values->>'idTipo')::int AS id_tipo_proposicao,
        (values->>'numero')::int AS numero,
        (values->>'ano')::int AS ano,
        values->>'ementa',
        (values->>'dataApresentacao')::date AS data_apresentacao,
        (values->'statusProposicao'->>'descricaoSituacao') AS situacao,
        values->>'tipoAutor' AS tipo_autor,
        values->>'ementaDetalhada' AS ementa_detalhada,
        values->>'texto',
        values->>'justificativa',
        values->>'keywords'
FROM (
  SELECT json_array_elements(values::json) AS values
  FROM temp_json
) elements;

END TRANSACTION;
-- importa proposicoes
