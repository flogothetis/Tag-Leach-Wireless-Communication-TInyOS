

#import <stdio.h>
#import <stdlib.h>
#import <math.h>





int  main ()
{
//member variables
int d ;
float range ;
int i,j ;
FILE* f;

f=fopen ("topology.txt","w");


do{
printf("Give me the diameter D \n  ");
scanf("%d",&d );
}while(d<2);

do {
  printf("Give me the signal range D \n  ");
  scanf("%f",&range );
} while(range<1 );


//build the grid d*d
int **a = (int **)malloc(d * sizeof(int *));
  for (i=0; i<d; i++)
       a[i] = (int *)malloc(d * sizeof(int));


// Insert the nodes in the Grid
for (i = 0; i < pow(d,2); i++) {
  a[i/d][i%d]=i;

}
int k1 ;
int k2;
range=floor(range);
for ( i = 0; i < d; i++) {
  for (j = 0; j < d; j++) {
    //  Search_Neightboors(f,floor(range);
          k1=i;
          for( int k=0;k<range ;k++)
          {
              k1-=1;
              if( k1<0) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[k1][j]);


          }
          k1=i;
          for( int k=0;k<range ;k++)
          {
              k1+=1;
              if( k1>d-1) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[k1][j]);


          }
          k1=j;
          for( int k=0;k<range ;k++)
          {
              k1-=1;
              if( k1<0) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[i][k1]);


          }
          k1=j;
          for( int k=0;k<range ;k++)
          {
              k1+=1;
              if( k1>d-1) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[i][k1]);


          }
          k1=i;
          k2=j;
          int counter =sqrt ( 2) ;
          while (counter <= range )
          {
              k1-=1;
              k2+=1;
              if( k1<0 || k2 > d-1  ) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[k1][k2]);

            counter += sqrt(2);
          }



          k1=i;
          k2=j;
           counter =sqrt ( 2) ;
          while (counter <= range )
          {
              k1-=1;
              k2-=1;
              if( k1<0 || k2 <0) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[k1][k2]);

                counter += sqrt(2);

          }
          k1=i;
          k2=j;
          counter =sqrt ( 2) ;
         while (counter <= range )
         {
              k1+=1;
              k2-=1;
              if( k1>d-1 || k2 <0) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[k1][k2]);

                  counter += sqrt(2);
          }
          k1=i;
          k2=j;
          counter =sqrt ( 2) ;
         while (counter <= range )
         {
              k1+=1;
              k2+=1;
              if( k1>d-1 || k2 >d-1) break ;
              else
              fprintf(f,"%d %d -0.0\n",a[i][j],a[k1][k2]);

                counter += sqrt(2);
          }




  }
}
fclose(f);



}
