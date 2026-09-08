/// Copia embedded di cani.csv, usata dal seed (anche nei test senza asset).
const caniCsvSource = r'''n.,nome,sesso,dataNascita,nascitaPresunta,sterilizzato,dataSterilizzazione,razza,taglia,pesoKg,mantello,microchip,iscrittoAnagrafe,provenienza,modalitaIngresso,dataIngresso,settore,box,stato,statoDal,adottabile,conPersone,conCani,conGatti,conBambini,carattere,slogan,descrizione,noteCarattere,referente,pubblicato,note
1,Orso,M,17/03/2021,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
2,Bailys,F,17/03/2021,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
3,Lana,F,17/03/2021,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
4,Alfa,F,17/03/2021,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
5,Evelin,F,17/03/2021,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
6,Igor,M,17/05/2017,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
7,Ettore,M,09/01/2022,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
8,Gina,F,11/10/2013,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
9,Max,M,02/01/2022,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
10,Louis,M,02/01/2022,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
11,Luce,M,02/01/2022,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
12,Molly,F,02/01/2022,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
13,Tears,F,02/01/2022,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
14,Plasmon,M,08/03/2021,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
15,Petunia,F,18/05/2018,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
16,Lara,F,18/08/2020,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
17,Bruno,M,10/04/2018,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
18,Panna,F,04/03/2019,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
19,Otto,M,10/01/2018,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
20,Sara,F,15/04/2020,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
21,Cicorietta,F,02/10/2018,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
22,Cometa,F,18/10/2013,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
23,Pluto,M,24/06/2017,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
24,Giorgio,M,01/03/2019,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
25,Flora,F,04/03/2019,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
26,Mami,F,15/03/2019,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
27,Totò,M,11/03/2018,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
28,Doris,F,24/06/2017,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
29,Biamin,F,06/06/2017,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
30,Alfie,M,10/02/2022,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
31,Becca,F,10/02/2022,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,"Nell'elenco originale numerata 31, come Vienna"
32,Vienna,F,21/03/2018,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,"Nell'elenco originale numerata 31, come Becca"
33,Mirtillo,M,14/01/2018,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
34,Nala,F,11/09/2018,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
35,Daitan,M,10/05/2014,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
36,Leone,M,11/09/2018,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
37,Wolf,M,04/03/2015,NO,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
38,Rossana,F,19/06/2017,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
39,Diana,F,02/03/2019,NO,SI,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,
40,Mimmo,M,,,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,Data di nascita non presente nell'elenco originale
41,Simba,M,,,NO,,,,,,,,Corleto Perticara (PZ),,,,,in_rifugio,,,,,,,,,,,,,Data di nascita non presente nell'elenco originale
42,Duca,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"
43,Aramis,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"
44,Portos,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"
45,Dartagnan,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"
46,Ciccio,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"
47,Chicca,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"
48,Louise,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"
49,Thelma,,,,,,,,,,,,Stigliano (MT),,,,,in_rifugio,,,,,,,,,,,,,"Elenco Stigliano: sesso, data di nascita e sterilizzazione da rilevare"

''';