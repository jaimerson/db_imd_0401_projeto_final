/*
  Mostra a soma das despesas de cada deputado agrupadas por ano e tipo da despesa
  Ex.:
         total      |      nome       | ano  |                       tipo_despesa
--------------------+-----------------+------+-----------------------------------------------------------
 R$       10.296,16 | ANTÔNIO JÁCOME  | 2015 | COMBUSTÍVEIS E LUBRIFICANTES.
 R$       18.189,00 | ANTÔNIO JÁCOME  | 2015 | MANUTENÇÃO DE ESCRITÓRIO DE APOIO À ATIVIDADE PARLAMENTAR
*/
SELECT
  to_char(sum(valor_documento),'"R$ "999G999G999D99') as total,
  nome,
  ano,
  tipo_despesa
FROM
  despesas
  INNER JOIN deputados USING(id_deputado)
GROUP BY id_deputado, nome, ano, tipo_despesa
ORDER BY nome;
