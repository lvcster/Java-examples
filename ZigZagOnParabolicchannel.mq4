#property indicator_chart_window // в окне инструмента
#property indicator_buffers 7
#property indicator_color1 Aqua
#property indicator_color2 Blue
#property indicator_color3 Red
#property indicator_width3 1
#property indicator_color4 Lime
#property indicator_width4 1
#property indicator_color5 Red
#property indicator_width5 1
#property indicator_color6 Lime
#property indicator_width6 1


extern double Step=0.02; // начальное значение и шаг
extern double Maximum=0.2; // конечное значение

extern bool ExtremumsShift=1; // положение экстремумов: 0 - по времени их определния; 1 - по их фактическому положению 
extern int History=0; // кол-во баров предыстории; 0 - все
extern int SignalGap = 4;
extern int ShowBars = 500;

int dist=24;

double b1[];
double b2[];
double b3[];
double b4[];

//--
double   Peak[], // буфер ZigZag по пикам
         Trough[], // буфер ZigZag по впадинам
         SAR[]; // буфер Parabolic

//=============================================================
int init()
  {
   SetIndexBuffer(0,Peak); // пики
   SetIndexStyle(0,DRAW_ZIGZAG);
   SetIndexLabel(0,"Peak");
   SetIndexEmptyValue(0,0.0);

   SetIndexBuffer(1,Trough); // кресты, т.е. впадины)))
   SetIndexStyle(1,DRAW_ZIGZAG);
   SetIndexLabel(1,"Trough");
   SetIndexEmptyValue(1,0.0);

   SetIndexBuffer(2,SAR); // Параболик
   SetIndexStyle(2,DRAW_ARROW);
   SetIndexArrow(2,159);
   SetIndexLabel(2,"SAR");
   SetIndexEmptyValue(2,0.0);

   SetIndexStyle(3,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(4,DRAW_LINE,STYLE_SOLID,1);
   SetIndexStyle(5,DRAW_ARROW,STYLE_SOLID,1);
   SetIndexStyle(6,DRAW_ARROW,STYLE_SOLID,1);
   
   SetIndexBuffer(3,b1);
    SetIndexEmptyValue(3,0.0);
    SetIndexEmptyValue(4,0.0);
    SetIndexEmptyValue(5,0.0);
    SetIndexEmptyValue(6,0.0);
   SetIndexBuffer(4,b2);
   SetIndexBuffer(5,b3);
   SetIndexBuffer(6,b4);
   
   SetIndexArrow(5,234);
   SetIndexArrow(6,233);

   
   return(0);
  }

//=============================================================
int start()
  {
   static int BarsPrev; // значение Bars на пред.баре
   bool MissBars=Bars-BarsPrev>1; // 1 - есть пропущенные бары
   bool NewBar=Bars-BarsPrev==1; // 1 - первый тик нулевого бара
   if(MissBars && BarsPrev!=0) BarsPrev=reinit(); // проущенные бары в процессе - пересчет заново
   
   int limit=Bars-BarsPrev-(BarsPrev==0); BarsPrev=Bars; // кол-во пересчетов
   if(History!=0 && limit>History) limit=History-1; // кол-во пересчетов по истории

   for(int i=limit; i>=0; i--) // цикл по непосчитанным и предпоследнему барам
     {   
      
      SAR[i]=iSAR(NULL,0,Step,Maximum, i); // Параболик
      double mid[2]; // ср. цена
      mid[0]=(High[i]+Low[i])/2; // ср.цена на текущем баре
      mid[1]=(High[i+1]+Low[i+1])/2; // ср.цена на пред.баре

      static int j; // счетчик смещения между моментом определеня экстремума и его положением во времени
      static bool dir; // флаг направления; 0 - вниз, 1 - вверх
      static double h,l; // текущие экстремальные значения
      int shift; // смещение между моментом определеня экстремума и его положением во времени

      if(i>0) j++; // если бар завершен, то инкремент счетчика смещения
      if(dir) // ловля  пика
        {
         if(h<High[i]) {h=High[i]; j=NewBar;} 
         if(SAR[i+1]<=mid[1] && SAR[i]>mid[0]) // переворот Параболика вниз
           {
            shift=i+ExtremumsShift*(j+NewBar); // смещение
            Peak[shift]=h; 
            dir=0; // направление вниз
            l=Low[i]; j=0; // текущий максимум, сброс счетчика смещения
           }
        }
      else // ловля впадины
        {
         if(l>Low[i]) {l=Low[i]; j=NewBar;} // текущий минимум; сброс счетчика смещения
         if(SAR[i+1]>=mid[1] && SAR[i]<mid[0]) // переворот Параболика вверх
           {
            shift=i+ExtremumsShift*(j+NewBar); // смещение
            Trough[shift]=l; // впадина
            dir=1; // направление вверх
            h=High[i]; j=0; // текущий максимум, сброс счетчика смещения
           }
        }
     }
   for(i=limit; i>=0; i--) // цикл по непосчитанным и предпоследнему барам
     {   
      b1[i]=0;
      b2[i]=0;
      b3[i]=0;
      b4[i]=0;
      
      if (Peak[i]>0) {
        b3[i]=High[i]+SignalGap*Point;
        b1[i]=High[i];
      }
      
      if (Trough[i]!=0) {
        b4[i]=Low[i]-SignalGap*Point; 
        b2[i]=Low[i];  
      } 
    
    } 
   if(MissBars) Print("limit: ",limit," Bars:",Bars," IndicatorCounted: ",IndicatorCounted());

   return(0);
  }
//=============================================================

// ф-я дополнительной инициализации
int reinit()
  {
   ArrayInitialize(Peak,0.0);
   ArrayInitialize(Trough,0.0);
   ArrayInitialize(SAR,0.0);

   return(0);
  }
 