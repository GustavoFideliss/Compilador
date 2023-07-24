#include <ctype.h>

#define TAM_TAB 100
#define MAX_PAR 20


enum 
{
    INT, 
    LOG
};

#define TAM_PIL 100
struct 
{
    int valor;
    char tipo; // 'r' = rotulo, 'n' =  nvars, 'p' = posicao, 't' = tipo

} pilha[TAM_PIL];

int topo = -1;


struct elemTabSimbolos {
    char id[100];       //identificador;
    int end;            //emdereco local global ou deslocamento local;
    int tip;            // tipo
    char cat;           // categoria: 'f' = FUN, 'p' = PAR, 'v' = VAR
    char esc;            // escopo: 'g' = GLOBAL, 'l' = LOCAL
    int rot;            // rotulo especifico para funcao
    int npa;            // numero de parametros (para funcao)
    int par[MAX_PAR];   // tipos dos parametros (para funcao)
} tabSimb[TAM_TAB], elemTab;


/*
//Desenvolver uma rotina para ajustar o endereco dos parametros 
//na tatebla de simbolos e o vetor de parametros da funcao
//depois que for cadastrado o ultimo parametro
*/


/*
//
//*/

int desempilha(char tipo);
void empilha (int valor, char tipo);

int posTab = 0; 

void maiscula (char *s) {
    for(int i = 0; s[i]; i++)
        s[i] = toupper(s[i]);
}

int buscaSimbolo(char *id)
{
    int i;
    //maiscula(id);
    for (i = posTab - 1; strcmp(tabSimb[i].id, id) && i >= 0; i--)
        ;
    if (i == -1) {
        char msg[200];
        sprintf(msg, "Identificador [%s] não encontrado!", id);
        yyerror(msg);
    }
    return i;
}


int simbolo_existe(char *id, char escopo)
{
    int i = 0;
    for (i = 0; i <= posTab; i++)
    {
        if (tabSimb[i].esc == escopo && strcmp(tabSimb[i].id, id) == 0)
        {
            return 1;
        }
    }
    return 0;
}

void insereSimbolo(struct elemTabSimbolos elem)
{
    // int i = pos_tab -1;
    if (posTab == TAM_TAB)
        yyerror("Tabela de Simbolos Cheia!");

    if (simbolo_existe(elem.id, elem.esc))
    {
       char msg[200];
        sprintf(msg, "Identificador [%s] duplicado!", elem.id);
        yyerror(msg);
    }
    // maiuscula(elem.id);
    tabSimb[posTab] = elem;
    posTab++;
}



void mostraTabela () {
    puts("Tabela de Simbolos");
    puts("------------------------------------------");
    printf("\n%30s | %s | %s | %s | %s | %s | %s | %s \n", "ID", "END", "TIP" , "CAT", "ESC", "ROT", "NPA", "PAR");
    for(int i = 0; i < 50; i++) 
        printf(".");
    for(int i = 0; i < posTab; i++){
        printf("\n%30s | %3d | %s | %3c | %3c | %3d | %3d |", tabSimb[i].id, tabSimb[i].end, tabSimb[i].tip == INT? "INT" : "LOG", 
        tabSimb[i].cat, tabSimb[i].esc, tabSimb[i].rot, tabSimb[i].npa);
        int x =0;
        if (tabSimb[i].cat == 'F' )
        {
            for(int j = i; j < i + tabSimb[i].npa; j++){
                
                printf("[%s]",tabSimb[i].par[x] == INT? "INT" : "LOG");
                printf("->");
                x++;
                if(j +1  ==   i + tabSimb[i].npa)
                    printf("NULL");
            }
        }
    }
    printf("\n");
   
}




// estrutura da pilha semantica
// usada para enderecos, variaveis, rotulos


#define TAM_PIL 100


void empilha(int valor, char tipo) {
    if (topo == TAM_PIL)
        yyerror("Pilha semântica cheia");
    pilha[++topo].valor = valor;
    pilha[topo].tipo = tipo;
}

int desempilha(char tipo) {
    if (topo == -1)
        yyerror("Pilha semântica vazia");
    if(pilha[topo].tipo != tipo){
        char msg[100];
        sprintf(msg, "Desempilha esperando [%c], encontrado [%c]", tipo, pilha[tipo].tipo);
        yyerror(msg);
    }
    return pilha[topo--].valor;
}

void testaTipo(int tipo1, int tipo2, int ret) 
{
    int t1 = desempilha('t');
    int t2 = desempilha('t');
    if (t1 != tipo1 || t2 != tipo2)
        yyerror("Incompatibilidade de tipo");
    empilha(ret, 't');
}

void mostrapilha(){
    int i = topo;
    printf ("Pilha = [");
    while(i>=0){
        printf("%d,%c ", pilha[i].valor, pilha[i].tipo);
        i--;
    }
    printf("]\n");
}


void ajustaParametros(int npar)
{
    int i = -3;
    int j = posTab - 1;

    while(tabSimb[j].cat != 'F'){
        tabSimb[j].end = i--;
        j--;
    }
    tabSimb[j].npa = npar;
    tabSimb[j].end = i;
    mostraTabela();

}

void removeVariaveisLocais(int npa, int nvarL)
{
    posTab -= npa;
    posTab -= nvarL;
    mostraTabela();
}