#include "xparameters.h"
#include "xil_io.h"
#include "xuartlite.h"
#include "math.h"
#include "xuartlite_l.h"

XUartLite UartLite;
u8 rcvChar;

u32 coeff [25];
u8 recvBuffer[50];
int recvCount;
int i;



int sign;
int integerPart;
int pointPos;
long unsigned int fractionPart;
double fractionDec;

double numDouble;
/*u32 num;
double y;
double x;*/
u8 recvchar;
int j;
int newflag;
u32 x;
u32 y;
UINTPTR addr;
int main()
{

	

xil_printf("asd");
while(1)
{
	for(j=0;j<25;j++)
	{


			integerPart=0;
			fractionPart=0;
			recvCount=0;
			newflag=0;

			while(recvBuffer[recvCount-1]!=10)
			{

				
				recvchar=XUartLite_RecvByte(XPAR_UARTLITE_0_BASEADDR);
				++recvCount;
				recvBuffer[recvCount-1]=recvchar;
				XUartLite_SendByte(XPAR_UARTLITE_0_BASEADDR,recvchar);

				if(recvBuffer[recvCount-1]=='.')
				{
					pointPos=recvCount-1;
				}

			}

			if(recvBuffer[0]=='+')
			{
				sign=0;
			}else
			{
				sign=1;
			}


			for(i=1;i<pointPos;i++)
			{
				integerPart+=(recvBuffer[i]-48) *pow(10,pointPos-i-1);
			}

			for(i=pointPos+1;i<recvCount-2;i++)
			{
					fractionPart+=(recvBuffer[i]-48) *pow(10,recvCount-2-i-1);
			}

			numDouble=((double)fractionPart/(pow(10,recvCount-2-pointPos-1)))+(double)integerPart;
			numDouble=numDouble*(1<<8);
			if(sign)
			{
				numDouble=numDouble*(-1);
			}


			



			
		coeff[j]=(u32)round(numDouble);

		Xil_Out32(XPAR_APB_M_BASEADDR+j,coeff[j]);

	}

	for(i=0;i<25;i++)
	{
	Xil_Out32(XPAR_APB_M_BASEADDR+i,coeff[i]);
	}

}


	return 0;
}


