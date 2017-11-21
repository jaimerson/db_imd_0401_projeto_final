/* Functions & Triggers */
/*
  partido_por_nome - Retorna o partido para um dado nome
*/
CREATE OR REPLACE FUNCTION id_from_uri(_id_deputado INT, _uri TEXT)
RETURNS TABLE (
  id_deputado INT, id_partido INT
) AS
$$
BEGIN
  RETURN QUERY
  SELECT _id_deputado, r::INT
  FROM substring(_uri FROM (position('partidos/' IN _uri) + 9) FOR char_length(_uri)) r;
END;
$$ LANGUAGE plpgsql;

/*
  add_despesas_by_file - Adicionar despesas com base nos arquivos da pasta despesas
*/
CREATE OR REPLACE FUNCTION add_despesas_by_file()
RETURNS void AS $$
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
$$ LANGUAGE plpgsql;

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
    RAISE NOTICE 'Duração de uma legislatura não pode ser maior que 4 anos.';
  END IF;

  RETURN NEW;
END;
$legislaturas_gatilho$ LANGUAGE plpgsql;

CREATE TRIGGER legislaturas_gatilho BEFORE INSERT OR UPDATE
ON legislaturas
FOR EACH ROW EXECUTE
PROCEDURE testa_duracao();
