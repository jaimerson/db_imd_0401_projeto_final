-- importa proposicoes
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
-- importa proposicoes

