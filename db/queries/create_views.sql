/* Views */
/*
  vw_deputados_gastos_mensal - Retorna o gasto mensal de cada deputado
*/
CREATE VIEW vw_deputados_gastos_mensal AS
SELECT d.nome, DATE_PART('month', de.data_documento) AS month, d.sigla_uf, SUM(de.valor_documento)
FROM despesas de
  JOIN deputados d on de.id_deputado = d.id_deputado
GROUP BY d.nome, month, d.sigla_uf
ORDER BY d.nome;

/*
  vw_deputados_gastos_totais - Retorna o gasto total de cada deputado
*/
CREATE VIEW vw_deputados_gastos_totais AS
SELECT d.nome, d.sigla_uf, SUM(de.valor_documento)
FROM despesas de
  JOIN deputados d on de.id_deputado = d.id_deputado
GROUP BY d.nome, d.sigla_uf
ORDER BY d.nome;


/*
  vw_proposicoes_deputados - Retorna as proposicoes agrupadas por cada
  deputado.
*/
CREATE VIEW vw_proposicoes_deputados AS
SELECT d.nome, p.ementa
FROM deputados d
  JOIN deputados_proposicoes dp ON d.id_deputado = dp.id_deputado
  JOIN proposicoes p ON p.id_proposicao = dp.id_proposicao
GROUP BY d.nome, p.ementa;

/*
  vw_usuarios_deputados - Retorna a lista de deputados seguduidos por cada usuario.
*/
CREATE VIEW vw_usuarios_deputados AS
SELECT u.nome as usuario, d.nome as deputado, d.sigla_uf
FROM inscricoes i
	JOIN deputados d ON d.id_deputado = i.id_deputado
  JOIN usuarios u ON u.id_usuario = i.id_usuario;

/*
  vw_votos_deputados - Retorna a lista de votos de cada usuario por proposicao
*/
CREATE VIEW vw_votos_deputados AS
SELECT d.nome, d.sigla_uf, v.voto, p.ementa
FROM votos v
	JOIN deputados d ON d.id_deputado = v.id_deputado
  JOIN proposicoes p ON p.id_proposicao = v.id_proposicao;
