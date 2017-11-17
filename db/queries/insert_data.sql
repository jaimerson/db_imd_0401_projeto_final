-- CREATE TEMPORARY TABLE temp_json (values TEXT) ON COMMIT DROP;
-- COPY temp_json FROM '<%= File.expand_path(File.join(__dir__, 'data', 'referencias', 'tiposProposicao.json')) %>';
--
-- -- edit the <%# ... %> for the absolute path if needed
--
-- -- INSERT INTO tipos_proposicao ('id_proposicao', 'sigla', 'nome', 'descricao')
-- SELECT values->>'id' AS id_proposicao,
--        values->>'sigla',
--        values->>'nome',
--        values->>'descricao'
-- FROM (
--   SELECT json_array_elements(replace(values,'\','\\')::json) AS values
--   FROM temp_json
-- ) elements;


