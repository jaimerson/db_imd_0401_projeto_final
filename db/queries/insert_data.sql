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

COMMIT TRANSACTION;
-- importa tipos_proposicao

-- importa legislaturas
BEGIN TRANSACTION;

CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'legislaturas.json')) %>'
CSV quote e'\x01' delimiter e'\x02';

-- edit the <%# ... %> for the absolute path if needed

INSERT INTO legislaturas (id_legislatura, data_inicio, data_fim)
SELECT (values->>'id')::int AS id_legislatura,
       (values->>'dataInicio')::date as data_inicio,
       (values->>'dataFim')::date as data_fim
FROM (
  SELECT json_array_elements(values::json) AS values
  FROM temp_json
) elements;

COMMIT TRANSACTION;
