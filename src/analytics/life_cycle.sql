--curiosa -> idade < 7
--fiel -> recência < 7 e recência =< 14
--turista -> recência =< 14
--desencatado -> recência =< 28
--zumbi -> recência > 28
--reconquistado -> recencia < 7 e recência_anterior >= 14 e <= 28
--reborn -> recencia > 28 e recência_anterior >= 14 e <= 28

with tb_daily as (

SELECT DISTINCT
    IdCliente, 
    substr(DtCriacao,0,11) as dtDia 
from transacoes
),

tb_idade as (
select 
    IdCliente,
    --min(dtDia) as DtPrimeiraTransacao,
    cast(max(julianDay('now') - julianDay(dtDia)) as int) as qtdeDiasPrimeiraTransacao,
    cast(min(julianDay('now') - julianDay(dtDia)) as int) as qtdeDiasUltimaTransacao

from tb_daily 
group by iDCliente
),


tb_rn as (
select *,
    row_number() OVER (PARTITION BY IdCliente order by dtDia DESC) as rnDia
from tb_daily
),

tb_penultima_ativacao as (
select *,
cast(julianDay('now') - julianDay(dtDia) as int) as qtdePenultimaTranscao
 from tb_rn
where rnDia = 2
),

tb_lifeCycle as (
select 
    t1.*,
    t2.qtdePenultimaTranscao,
    CASE 
        WHEN qtdeDiasPrimeiraTransacao <= 7 THEN '01-CURIOSO'
        WHEN qtdeDiasUltimaTransacao <= 7 AND (qtdePenultimaTranscao - qtdeDiasUltimaTransacao) < 15 THEN '02-FIEL'
        WHEN qtdeDiasUltimaTransacao BETWEEN 8 AND 14 THEN '03-TURISTA'
        WHEN qtdeDiasUltimaTransacao BETWEEN 15 AND 28 THEN '04-DESENCANTADA'
        WHEN qtdeDiasUltimaTransacao > 28 THEN 'ZUMBI'
        WHEN qtdeDiasUltimaTransacao <= 7 AND (qtdePenultimaTranscao-qtdeDiasUltimaTransacao) BETWEEN 15 AND 28 THEN '02-RECONQUISTADO'
        WHEN qtdeDiasUltimaTransacao <= 7 AND (qtdePenultimaTranscao-qtdeDiasUltimaTransacao) > 28 THEN '02-REBORN'
    END AS descLifeCycle
from tb_idade as t1
left join tb_penultima_ativacao as t2
on t1.IdCliente = t2.IdCliente
)

select * from tb_lifeCycle
where descLifeCycle IS NULL