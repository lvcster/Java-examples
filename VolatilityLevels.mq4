#property copyright "Владислав Васильев"
#property link      "http://www.mql4.com/ru/users/incognitos"
// v1.1

//----------------------------------------------------------------------------------------------------------------------------------+
// Рисует внутри дня уровни волатильности (среднеднев. и макс. за несколько дней) докуда может дойти цена.                          |
// Дальше них сегодня цена не пойдёт с >95% степенью вероятности.                                                                   |
// (Почему указываю такой процент? Просто 90% - это 1 раз из 10, а волатильность выше максимальной за 10 дней бывает весьма редко.) |
// Алгоритм: Волатильность предыдущих дней (за PeriodDays) добавляется к мин/макс. этого дня - получаем уровни с каждой стороны.    |
// В течении дня появляются новые экстремумы, поэтому к середине дня границы индикатора смещаются.                                  | 
// Уровни рисуются с начала текущих суток (00:00).                                                                                  |                                                                                                                  
// 2 варианта рисования: квадратом или линиями.                                                                                     |
//----------------------------------------------------------------------------------------------------------------------------------+
#property indicator_chart_window

   extern   int   PeriodDays=20;  // период дней.  1 = вчера, 20 = четыре рабочие недели (месяц)

// рисовать квадрат. нижняя и верхняя границы - среднеднев. и макс. волатильности, право-лево - границы суток   
   extern   bool  ShowRectangle = true;  
// рисовать линии 
   extern   bool  ShowLinesAvrDaysVol = false;  // рисовать линии среднедневной вол.
   extern   bool  ShowLinesMaxDaysVol = false;  // рисовать линии макс.дневной вол.
// цвет и стиль линии
   extern   color Color = LightBlue;     // по умолчанию цвет LightBlue, символиз. остывание трэнда, возможный отскок как от льда
   extern   int   Style = STYLE_DASH;  

   extern   bool  ShowVolsInComment=false;  // Показывать комментарием значения волатильности


//+------------------------------------------------------------------+
int init()
{
   // Если вкл.отображение квадрата, включатели отображения линиями не принимать во внимание
   //if (ShowRectangle) {ShowLinesAvrDaysVol=false; ShowLinesMaxDaysVol=false;} 
    
   ObjectDelete ("волатильность вверх");
   ObjectDelete ("волатильность вниз"); 
   ObjectDelete ("среднеднев.волатильность вверх");
   ObjectDelete ("среднеднев.волатильность вниз");
   ObjectDelete ("макс.днев.волатильность вверх");
   ObjectDelete ("макс.днев.волатильность вниз");
}

int deinit()
{
 if (ShowRectangle){
   ObjectDelete ("волатильность вверх");
   ObjectDelete ("волатильность вниз"); 
 } else {
   ObjectDelete ("среднеднев.волатильность вверх");
   ObjectDelete ("среднеднев.волатильность вниз");
   ObjectDelete ("макс.днев.волатильность вверх");
   ObjectDelete ("макс.днев.волатильность вниз");}
 if (ShowVolsInComment)  Comment("");  
}


//+------------------------------------------------------------------+
int start()
{   
   if (!IsNewBarM1()) return;   // запуск раз в минуту, чтоб не тратить зря время процессора; проверка появления нового бара M1
   
   string volcomment = LevelsDayVolatility (PeriodDays, ShowRectangle, ShowLinesAvrDaysVol,ShowLinesMaxDaysVol, Color,Style);

   if (ShowVolsInComment)  Comment(volcomment);     
   
}
//+------------------------------------------------------------------+



//---------------------------------------------------------------------------------------------------+
// Автор:  Владислав Васильев,  http://www.mql4.com/ru/users/incognitos                              |
// --------------------------------------------------------------------------------------------------|
// Рисует внутри дня уровни среднедневной (за DayVlt дней) волатильности, докуда может дойти цена    |
//---------------------------------------------------------------------------------------------------+ 
#define SEKUNDvSUTKAH 86400   // число секунд в сутках = 60*60*24
string LevelsDayVolatility (int DayVlt = 5, //  DayVlt - кол-во дней за которые вычисляется среднедневная волатильность
         bool ShowRectangle=true, bool ShowLinesAvrDaysVol=false, bool ShowLinesMaxDaysVol=false, 
         int Color=Black, int Style=STYLE_DASH)   
{  
   datetime timeDayBegin = iTime(NULL,PERIOD_D1,0);    // время начала текущих суток
   int ibarM1DayBegin = iBarShift(NULL,PERIOD_M1,timeDayBegin);   // номер бара начала этих суток (M1 - наименьший таймфрейм по которому моделируются все тики) 
   double DayMin = iLow(NULL,PERIOD_M1, iLowest(NULL,PERIOD_M1,MODE_LOW,ibarM1DayBegin));   // плавающий дневной мин
   double DayMax = iHigh(NULL,PERIOD_M1,iHighest(NULL,PERIOD_M1,MODE_HIGH,ibarM1DayBegin)); // плавающий дневной макс
   double avgDaysVltPts = iATR(NULL,PERIOD_D1,DayVlt,1);   // среднеднев.волатильность
   double maxDaysVltPts=MaxDaysVolatility(DayVlt);         // макс.днев.волатильность
      
   if (ShowRectangle){
      rectangle("волатильность вверх", timeDayBegin, DayMin+avgDaysVltPts, timeDayBegin+SEKUNDvSUTKAH, DayMin+maxDaysVltPts, Color, Style, 1);
      rectangle("волатильность вниз",  timeDayBegin, DayMax-avgDaysVltPts, timeDayBegin+SEKUNDvSUTKAH, DayMax-maxDaysVltPts, Color, Style, 1);
      }

   if (ShowLinesAvrDaysVol){
      writeline ("среднеднев.волатильность вверх", DayMin + avgDaysVltPts, Color, Style, 1);  // возмож.днев.волатильность вверх
      writeline ("среднеднев.волатильность вниз",  DayMax - avgDaysVltPts, Color, Style, 1);  // возмож.днев.волатильность вниз  
      }   
   if (ShowLinesMaxDaysVol){
      writeline ("макс.днев.волатильность вверх", DayMin + maxDaysVltPts, Color, Style, 1);  // возмож.днев.волатильность вверх
      writeline ("макс.днев.волатильность вниз",  DayMax - maxDaysVltPts, Color, Style, 1);  // возмож.днев.волатильность вниз   
      }
   
   // отладка
   /*Print (
   " maxDaysVltPts=",DS(maxDaysVltPts),    
   " avgDaysVltPts=",DS(avgDaysVltPts),
   " ThisDayMin=",DS(DayMin),
   " ThisDayMax=",DS(DayMax),
   " ibarlow=",ibarlow," time=",TimeToString(iTime(NULL,PERIOD_M1,ibarlow)),
   " ibarhi=",ibarhi," time=",TimeToString(iTime(NULL,PERIOD_M1,ibarhi)),
   " ibarM1DayBegin=",ibarM1DayBegin,
   " timeDayBegin=",TimeToString(timeDayBegin),
   " MaxDaysVolatility =",DS(MaxDaysVolatility(5))
   );*/
   
   if (ShowVolsInComment)  
      string comment = StringConcatenate("Среднеднев.волатильность =",DS(avgDaysVltPts)," пп, макс.днев.волатильность =",DS(maxDaysVltPts)," пп");
   return(comment);
}

double MaxDaysVolatility (int DayVlt = 5)   //  DayVlt - кол-во дней за которые вычисляется max.дневная волатильность
{  
   if (DayVlt<=0) {Alert("Индикатор волатильности: DayVlt должно быть >= 0");}
   double  maxdayvol;
   for (int iday=1; iday<=DayVlt; iday++) { 
      double maxofday=0, minofday=0;
      double dayvol = iHigh(NULL,PERIOD_D1,iday) - iLow(NULL,PERIOD_D1,iday);  
      if (dayvol > maxdayvol) maxdayvol=dayvol;} // int ibarmaxvol=iday;}
   return (maxdayvol);
}


//---------------------------------------------------------------------------------------------/
// отрисовка прямоугольника в основном окне:
//---------------------------------------------------------------------------------------------/
void rectangle (string name, datetime time1, double Price1, datetime time2, double Price2, color Color, int Style, int Width)
{
 ObjectDelete(name);
 ObjectCreate (name, OBJ_RECTANGLE, 0, time1, Price1, time2, Price2);
 ObjectSet(name, OBJPROP_COLOR, Color);
 ObjectSet(name, OBJPROP_STYLE, Style);
 ObjectSet(name, OBJPROP_WIDTH, Width);
}

//---------------------------------------------------------------------------------------------/
// отрисовка горизонт. линии в основном окне:
//---------------------------------------------------------------------------------------------/
void writeline (string Linename, double Price, color Color, int Style, int Width)
{
 ObjectDelete(Linename);
 ObjectCreate(Linename, OBJ_HLINE, 0, 0, Price);
 ObjectSet(Linename, OBJPROP_COLOR, Color);
 ObjectSet(Linename, OBJPROP_STYLE, Style);
 ObjectSet(Linename, OBJPROP_WIDTH, Width);
}
//---------------------------------------------------------------------------------------------/


//+-------------------------------------------------------------------------------------+
//| Приведение десятичного типа в строковый с числом знаков Digits
//+-------------------------------------------------------------------------------------+
string DS(double x) {return(DoubleToStr(x,Digits));}  


// ----------------------------------------------------------------------------|
// Запуск вызвавшей функции раз в минуту, чтоб не тратить зря время процессора |
// Использование:  if (!RunOnceMinute()) return;                               |
//-----------------------------------------------------------------------------+
bool IsNewBarM1() {   
   static datetime dPrevtime;  
   if (dPrevtime==0  ||  dPrevtime!=iTime(NULL,PERIOD_M1,0)) 
      {dPrevtime=iTime(NULL,PERIOD_M1,0);  
      return (true);}
   else return (false);  
}

