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
