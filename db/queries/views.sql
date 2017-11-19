/* Views */
/*
  vw_deputados_gastos_mensal - Retorna o gasto mensal de cada deputado
*/
CREATE VIEW vw_deputados_gastos_mensal AS
SELECT d.nome, d.siglaUf, DATE_PART('month', de.data_documento) AS month, SUM(de.valor_documento)
FROM despesas de
  JOIN deputados d on de.id_deputado = d.id_deputado
GROUP BY d.nome, month, d.siglaUf
ORDER BY month;

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
