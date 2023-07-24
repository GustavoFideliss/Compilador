%{
#include "lexico.c"
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "utils.c"

int contaVar;  // cortar o numero de variaveis
int contaVarL = 0 ; // cortar o numero de variaveis locais
int rotulo = 0; // marcar lugares no codigo para rotulos
int tipo;     // flag do tipo (INT - inteiro, LOG - logico)
char escopo;  // flag do escopo (G - global, L - local)
int npa;     // numero de parametros atuais
int posFun; // posição da funcao
int contaARGS = 0; // conta o numero de argumentos
%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_FACA
%token T_ENQTO
%token T_FIMENQTO
%token T_INTEIRO
%token T_LOGICO
%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV
%token T_ATRIBUI
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E
%token T_OU
%token T_NAO
%token T_ABRE
%token T_FECHA
%token T_V 
%token T_F 
%token T_IDENTIF
%token T_NUMERO
%token T_RETORNE
%token T_FUNC
%token T_FIMFUNC

%start programa 
%expect 1

%left T_E T_OU 
%left T_IGUAL 
%left T_MAIOR T_MENOR 
%left T_MAIS T_MENOS 
%left T_VEZES T_DIV 


%%


programa 
    : cabecalho 
        { contaVar = 0;
          escopo = 'G';
         }
    variaveis 
        { 
            mostraTabela();
            empilha(contaVar, 'n');    
        }
        // acrescentar as chamada para as funções
        //funcoes , criar um desvio
       rotinas
       T_INICIO lista_comandos T_FIM
        { 
            int conta = desempilha('n');
            if (conta)
                fprintf(yyout,"\tDMEM\t%d\n", conta); 
            fprintf(yyout,"\tFIMP\n");
        }
    ;


rotinas
    : /*sem funcoes*/
    |   {
            fprintf(yyout, "\tDSVS\tL0\n");
        }
    funcoes
            {
                fprintf(yyout, "L0\tNADA\n"); 
            } 
    ;

cabecalho 
    : T_PROGRAMA T_IDENTIF
        { fprintf(yyout,"\tINPP\n"); }
    ;

variaveis
    :
    | declaracao_variaveis
    { 
           if (escopo == 'G' && contaVar > 0) {
                fprintf(yyout,"\tAMEM\t%d\n", contaVar); 
                //empilha(contaVar, 'n');
            }
            else if(escopo == 'L' && contaVarL > 0){
                fprintf(yyout,"\tAMEM\t%d\n", contaVarL);
                //empilha(contaVarL, 'n');
            }
    }
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo 
    : T_LOGICO
        { tipo = LOG; }
    | T_INTEIRO
        { tipo = INT; }
    ;

lista_variaveis
    : lista_variaveis T_IDENTIF 
        {
          strcpy(elemTab.id, atoma);
          elemTab.end = contaVar;
          elemTab.tip = tipo;
          elemTab.esc = escopo;
          elemTab.cat = 'V';
          if (escopo == 'G'){
           elemTab.end = contaVar;
          }
          else{
            elemTab.end = contaVarL;
            contaVarL++;
          }
         insereSimbolo(elemTab);
         printf("%d",contaVar);
         contaVar++;
        }
    | T_IDENTIF
        { 
          strcpy(elemTab.id, atoma);
          elemTab.tip = tipo;
          elemTab.esc = escopo;
          elemTab.cat = 'V';
          if (escopo == 'G')
           elemTab.end = contaVar;
          else{
            elemTab.end = contaVarL;
            contaVarL++;
          }
          insereSimbolo(elemTab);
          printf("%d",contaVar);
          contaVar++;
        }
    ;
// regra para funcoes
funcoes
    : funcao funcoes
    | funcao
    ;

funcao 
    : T_FUNC tipo T_IDENTIF 
            {
                rotulo++;
                strcpy(elemTab.id, atoma);
                elemTab.end = contaVar;
                elemTab.tip = tipo;
                elemTab.esc = escopo;
                elemTab.cat = 'F';
                elemTab.rot = rotulo;
                elemTab.npa = 0;
                insereSimbolo(elemTab);
                contaVar++; 
                escopo = 'L';
                npa = 0;
                contaVarL = 0 ;
                posFun = buscaSimbolo(atoma);
                fprintf(yyout, "L%d\tENSP\n", rotulo);
                }
    T_ABRE parametros T_FECHA
    // ajustar deslocamento
    {
       ajustaParametros(npa);
    }
    variaveis 
    T_INICIO lista_comandos T_FIMFUNC
            {
                escopo = 'G';
                removeVariaveisLocais(npa, contaVarL);   
            }
    ;

parametros
    : /*vazio*/
    | parametro parametros
    ;

parametro
    : tipo T_IDENTIF
        {
            strcpy(elemTab.id, atoma);
            elemTab.end = npa;
            elemTab.tip = tipo;
            elemTab.esc = escopo;
            elemTab.cat = 'P';
            tabSimb[posFun].par[npa] = tipo;
            elemTab.rot = 0;
            insereSimbolo(elemTab);   
            npa++;
        }
    ;

lista_comandos
    : /*vazio*/
    | comando lista_comandos
    ;

comando 
    : entrada_saida
    | repeticao 
    | selecao
    | atribuicao 
    | retorne
    ;

retorne 
    : T_RETORNE 
    {
        if(escopo == 'G')
             yyerror("Retorne está declarado na main.");
    }
    expressao
    {
        int tip = desempilha('t');
        if (tip != tabSimb[posFun].tip)
            yyerror("Tipo de retorno incompativel\n");
         fprintf(yyout, "\tARZL\t%d\n", tabSimb[posFun].end);
         if (contaVarL > 0){
            fprintf(yyout, "\tDMEM\t%d\n", contaVarL);
        }
        fprintf(yyout, "\tRTSP\t%d\n", npa);
    }
    ;

entrada_saida
    : leitura
    | escrita
    ;


leitura 
    : T_LEIA T_IDENTIF
        
        { 
            int pos = buscaSimbolo(atoma);
                fprintf(yyout,"\tLEIA\n\tARZG\t%d\n", tabSimb[pos].end);  
        }
    ;

escrita 
    : T_ESCREVA expressao 
        {
            desempilha('t'); 
            fprintf(yyout,"\tESCR\n"); 
        }
    ;

repeticao 
    : T_ENQTO
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo); 
            empilha(rotulo, 'r');
        } 
    expressao T_FACA  
        {   
            int tip = desempilha('t');
            if (tip != LOG)
                yyerror("Incompatibilidade de tipo");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo); 
            empilha(rotulo, 'r');
        }
    lista_comandos
    T_FIMENQTO
        {
            int rot1 = desempilha('r');
            int rot2 = desempilha('r');
            fprintf(yyout,"\tDSVS\tL%d\nL%d\tNADA\n", rot2, rot1); 
        }
    ;

selecao 
    : T_SE expressao T_ENTAO 
        { 
            int tip = desempilha('t');
            if (tip != LOG)
                yyerror("Incompatibilidade de tipo");
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo);
            empilha(rotulo, 'r');
        }
    lista_comandos T_SENAO 
        {
            int rot = desempilha('r'); 
            fprintf(yyout,"\tDSVS\tL%d\nL%d\tNADA\n", ++rotulo, rot); 
            empilha(rotulo, 'r');
        }
    lista_comandos T_FIMSE
        {
            int rot = desempilha('r'); 
            fprintf(yyout,"L%d\tNADA\n", rot); 
        }
    ;

atribuicao 
    : T_IDENTIF
        {
            int pos = buscaSimbolo(atoma);
            empilha(pos, 'p');
        } 
       T_ATRIBUI expressao 
        { 
            int tip = desempilha('t');
            int pos = desempilha('p');
            if (tabSimb[pos].tip != tip)
                yyerror("Incompatibilidade de tipo!");
            if (escopo == 'G')
                fprintf(yyout,"\tARZG\t%d\n", tabSimb[pos].end); 
            else 
                fprintf(yyout,"\tARZL\t%d\n", tabSimb[pos].end); 
        }
    ;
expressao 
    : expressao T_VEZES expressao 
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tMULT\n"); 
        }
    | expressao T_DIV expressao 
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tDIVI\n"); 
        }
    | expressao T_MAIS expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tSOMA\n"); 
        } 
    | expressao T_MENOS expressao
        { 
            testaTipo(INT, INT, INT);
            fprintf(yyout,"\tSUBT\n"); 
        } 
    | expressao T_MAIOR expressao
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMMA\n"); 
        } 
    | expressao T_MENOR expressao 
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMME\n"); 
        }
    | expressao T_IGUAL expressao
        { 
            testaTipo(INT, INT, LOG);
            fprintf(yyout,"\tCMIG\n"); 
        } 
    | expressao T_E expressao 
        { 
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tCONJ\n"); 
        }
    | expressao T_OU expressao
        { 
            testaTipo(LOG, LOG, LOG);
            fprintf(yyout,"\tDISJ\n"); 
        } 
    | termo 
    ;

// A funcao e chamada como um termo numa expressão
identificador
    : T_IDENTIF
        {
            int pos = buscaSimbolo(atoma);
            empilha (pos, 'p');
        }
    ;

    
chamada
    :  { 

        int pos = desempilha('p');
        if (tabSimb[pos].esc == 'G')
            fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].end);
        else
            fprintf(yyout,"\tCRVL\t%d\n", tabSimb[pos].end);
        empilha(tabSimb[pos].tip, 't');

        }
    |T_ABRE 
        { 
            fprintf(yyout,"\tAMEM\t1\n");
        }  
    lista_argumentos 
    T_FECHA 
        {
            posFun = desempilha('p');
            if(contaARGS !=  tabSimb[posFun].npa)
                yyerror("Numero de parametros errado");
            fprintf(yyout, "\tSVCP\n");
            fprintf(yyout, "\tDSVS\tL%d\n", tabSimb[posFun].rot);
            empilha(tabSimb[posFun].tip, 't');
            contaARGS = 0; 
        }
    ; 



lista_argumentos
    : /* vazio */
    | expressao
    {
        int tipo = desempilha('t');
        for(int j=0; j < tabSimb[posFun].npa; j++){
            if(tabSimb[posFun].par[j] != tipo)
                yyerror("Tipo do parametro diferente do tipo do argumento"); 
        }
    }
     lista_argumentos 
    {
        contaARGS++;
    }
    ;


termo 
    : identificador chamada
    | T_NUMERO
        {   fprintf(yyout,"\tCRCT\t%s\n", atoma); 

            empilha(INT, 't');
    
        }
    | T_V 
        {   fprintf(yyout,"\tCRCT\t1\n"); 

            empilha(LOG, 't');
    
        }
    | T_F 
        {   fprintf(yyout,"\tCRCT\t0\n"); 

            empilha(LOG, 't');
    
        }
    | T_NAO termo
        { 

            int t = desempilha('t');

            if (t != LOG) yyerror ("Incompatibilidade de tipo!");
            fprintf(yyout,"\tNEGA\n"); 
    
            empilha(LOG,'t');
    
        }
    | T_ABRE expressao T_FECHA
    ;

%%


int main (int argc, char *argv[]) {
    char *p, nameIn[100], nameOut[100];
    argv++;
    if (argc < 2) {
        puts("\nCompilador Simples");
        puts("\n\tUso: ./simples <NOME>[.simples]\n\n");
        exit(10);
    }
    p = strstr(argv[0], ".simples");
    if (p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen (nameIn, "rt");
    if (!yyin) {
        puts("Programa fonte não encontrado!");
        exit(20);
    }
    yyout = fopen(nameOut, "wt");
    yyparse();
    puts("Programa ok!");
}