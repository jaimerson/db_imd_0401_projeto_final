/* Functions */
/*
  deputados_simplificado - Retorna a lista de deputados seguidos pelo usuário
                          passado como parâmetro
*/
CREATE OR REPLACE FUNCTION deputados_simplificado(_id_usuario INT)
RETURNS TABLE (
  nome VARCHAR(255), siglaUf CHAR(2), sigla VARCHAR(10)
) AS
$$
BEGIN
  RETURN QUERY
  SELECT d.id_deputado, d.nome, d.siglaUf, p.sigla
  FROM deputados d
    JOIN partidos p ON d.id_partido = p.id_partido
    WHERE d.id_deputado IN (SELECT d.id_deputado
                            FROM inscricoes i
                            WHERE d.id_deputado = i.id_deputado AND i.id_usuario = _id_usuario);
END;
$$ LANGUAGE plpgsql;

/* Stored procedures */
