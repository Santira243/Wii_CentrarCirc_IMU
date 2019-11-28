import hypermedia.net.*;

import de.voidplus.leapmotion.*;
import toxi.geom.*;  

// VARIABLES WBB
UDP udp_WBB;

int rectWidth;
float x;
float y;

int s;
int m;
int tiempo;

// VARIABLES IMUS
public class posme
{
  float[] q = new float [4];
  boolean loaded;
}

// Variables de los cuaterniones
float[] q = new float[4];
Quaternion quat_1 = new Quaternion(1, 0, 0, 0);
Quaternion quat_2 = new Quaternion(1, 0, 0, 0);
Quaternion quat_z = new Quaternion(1, 0, 0, 0);

// Variables para PUNTO FIJO-IMU
float[] pos_PuntoFijo = {0.0,0.0,0.0};    // Posición espacial del punto fijo de referencia
float[] pos_IMU   = {0.0,0.0,0.0};    // Posición espacial del IMU
int pos_vector = 0;          // Vector posición para el filtro promediador

// Variables para el filtro promediador
float[][] quat_1_m = new float [30][4];    // Filtrado de la posición del muslo
float[] quat_1_sum = new float [4];        // Para guardar la sumatoria de cuaterniones
Quaternion quat_1_PB = new Quaternion(1, 0, 0, 0);  // quat_1 con pasabajos
Quaternion quat_2_PB = new Quaternion(1, 0, 0, 0);  // quat_2 con pasabajos
float[] pos_PF_IMU = {0.0,0.0,0.0};    // Posición espacial del punto fijo

// Variables UDP IMU
UDP udp_IMU;
posme dev1 = new posme();
String message   = "1";          // Mensaje a enviar
String ip1       = "10.0.0.3";   // IP del IMU 1
int port         = 65506;        // Puerto de comunicación
  
// Otras variables IMU
float angulo;
float[] ang_crudo ={0.0,0.0,0.0,0.0};
float prom_ang;
float prom;
float aux_posicion;
float[] axis_q1;
float grabar_axis;
float barra_posicion;
float map_posicion;

int promedio;
int aux;

boolean grabar_pos = false;
boolean fijar_posicion ;
boolean aux_pos;

  
//------------------------------------------------------------------------//

void setup()
{
  size(1000, 600,P3D);
  noStroke();
  background(200);

  rectWidth = width/4;
  //Inicio circulo
  x = width/2;
  y = height/2;
  
   // UDP asociados al puerto de comunicación
  udp_WBB = new UDP( this, 4000);
  udp_WBB.listen( true );
  noStroke();
  
  udp_IMU = new UDP( this, 65506 );
  udp_IMU.listen( true );
  //udp_IMU.send( message, ip1, port );
    
  pos_PF_IMU[0] = 0.0;
  pos_PF_IMU[1] = 1.0;
  pos_PF_IMU[2] = 0.0;
  grabar_pos = false;
  fijar_posicion = false;
  aux_pos = false;
  grabar_axis = 0;
}

//------------------------------------------------------------------------//

float[] rot_q1 = quat_1_PB.toAxisAngle();

//------------------------------------------------------------------------//

void draw()
{
  background(200);
  stroke(0);
  //Líneas 
  line(0,height/2,width,height/2);
  line(width/2,0,width/2,height);
  noFill();
 // pushMatrix();
  //Circulo del centro
  ellipse(width/2, height/2, 50, 50);
  //Rectangulo: angulo
  rect(10,100,30,400);
  line(10,width/2,40,width/2);
    
  // -WBB
  // CENTRO: Circulo rojo
  if((x > width/2-20) && (x < width/2+20) && (y > height/2-40) && (y < height/2+40))
  {
    strokeWeight (6);   
    stroke(0,0,255);
    ellipse(width/2, height/2, 50, 50);
    noStroke();
    strokeWeight (1); 
   
   // Tiempo //
   
    if(s < 60)
    {
      s = (millis() - tiempo) / 1000;
     
      
      textSize(40);
      textAlign(CENTER);
      fill(0);
      text("TIEMPO", 150 + width/2, 50);
      text(m+":"+s, 150 + width/2, 100);
      s = s+1;
    }
    else
    {
      tiempo = millis();
      m = m + 1;
      s = 0;
    }
  }
  else
  {
    tiempo = millis();
  }
  //CIRCULO   
   fill(0);
   ellipse(x, y, 20, 20);
   //popMatrix();
   
  //-IMUS
  // Guardamos las rotaciones en las siguientes variables locales
  axis_q1 = rot_q1;
  pushMatrix();
  // Ubicación punto fijo
  translate(width / 2, (height / 2 - height / 4 - height / 8)   );
  //Posición del punto fijo
  pos_PuntoFijo[0] = modelX(0, 0, 0);
  pos_PuntoFijo[1] = modelY(0, 0, 0);
  pos_PuntoFijo[2] = modelZ(0, 0, 0);
    
  //Sistema punto fijo - persona
  pushMatrix();
  //rotate( axis_q1[0],-axis_q1[1],axis_q1[3],axis_q1[2]); // Rotación del IMU 1
  rotate( axis_q1[1]);
  //println(axis_q1[1]);
  
  translate(0, 210, 0);
  //Guardamos las coordenadas en las que se ubica el IMU
  pos_IMU[0] = modelX(0, 0, 0);
  pos_IMU[1] = modelY(0, 0, 0);
  pos_IMU[2] = modelZ(0, 0, 0);
  popMatrix();

  popMatrix();
 
  pushMatrix();
 
  //Barra de posición
  barra_posicion = abs(axis_q1[1])-(grabar_axis);
  println(barra_posicion);
  if(abs(barra_posicion) > 0.3)
  {
  barra_posicion = 0.3;
  }
  map_posicion = map(abs(barra_posicion), 0, 0.3, 0, 400);
  
 println("Posicion",map_posicion);
  
  fill(255,100,0);
  if(abs(map_posicion) > 200)
  {fill(255,0,0);}
  rect(10, 500, 30, -abs(map_posicion));
  popMatrix();
  
  fill(255);
  //text(promedio,50,50);
}



void receive( byte[] data, String ip1, int port ) 
{  
  data = subset(data, 0, data.length);
  String message = new String( data );
  //println(message);
  // Lee IMUS
  if( port == 65506)
  {
    // Traemos los datos que mandan los IMU por JSON
    JSONObject json = parseJSONObject(message);
    // Detecta errores, o se fija cuál IMU es y guarda la info en las variables correspondientes
    if (json == null)
    {
      println("JSONObject could not be parsed"); // Señal de error
    }
    else 
    {
      int disp =  json.getInt("Device"); // Lee el número de dispositivo (se lo dimos en el código de Arduino)
      if(disp == 1)
      {
        dev1.q[0] = ( json.getFloat("Q0"));  // qw
        dev1.q[1] = ( json.getFloat("Q1"));  // qx
        dev1.q[2] = ( json.getFloat("Q2"));  // qy
        dev1.q[3] = ( json.getFloat("Q3"));  // qz
        
        quat_1.set(dev1.q[0], dev1.q[1], dev1.q[2], dev1.q[3]); // Guarda la info del cuaternión en quat_1
        dev1.loaded = true;  // Indica que el dispositivo fue leído exitosamente
      }
    }
    // Movemos el puntero
    pos_vector++;
    if (pos_vector > 29)
    {
      pos_vector = 0;
    } 
    
    // Guardamos la info correspondiente en los vectores/matrices
    quat_1_m[pos_vector][0] = dev1.q[0];
    quat_1_m[pos_vector][1] = dev1.q[1];
    quat_1_m[pos_vector][2] = dev1.q[2];
    quat_1_m[pos_vector][3] = dev1.q[3];
    
    quat_1_PB.set(0,0,0,0);      
    
    quat_1_sum[0] = 0.0; quat_1_sum[1] = 0.0; quat_1_sum[2] = 0.0; quat_1_sum[3] = 0.0;
    
    // Hacemos sumatoria
    for (int i = 0; i <= 29; i++)
    {
      quat_1_sum[0] += quat_1_m[i][0];
      quat_1_sum[1] += quat_1_m[i][1];
      quat_1_sum[2] += quat_1_m[i][2];
      quat_1_sum[3] += quat_1_m[i][3];
    }
    
    // Dividimos por el total de elementos para obtener el promedio    
    quat_1_PB.set(quat_1_sum[0]/30,quat_1_sum[1]/30,quat_1_sum[2]/30,quat_1_sum[3]/30);
               
    // Guardamos la info angular
    rot_q1 = quat_1_PB.toAxisAngle();       
    
          
    // Armamos dos vectores para poder calcular el ángulo entre Punto Fijo e IMU
    float [] PF_IMU = {0.0,0.0,0.0};
   
    PF_IMU[0] = pos_PuntoFijo[0] - pos_IMU[0];
    PF_IMU[1] = pos_PuntoFijo[1] - pos_IMU[1];
    PF_IMU[2] = pos_PuntoFijo[2] - pos_IMU[2];
      
    //Grabar la posicion correcta del IMU
    if( grabar_pos)
    {
      grabar_axis = abs(axis_q1[1]);
          
      //pos_PF_IMU[0] = PF_IMU[0];
      //pos_PF_IMU[1] = PF_IMU[1];
      //pos_PF_IMU[2] = PF_IMU[2];
      grabar_pos = false;
    } 
    
    // Calculamos el ángulo
    float prodPunto =  PF_IMU[0]*pos_PF_IMU[0] +  PF_IMU[1]*pos_PF_IMU[1] + PF_IMU[2]*pos_PF_IMU[2];
    //float prodVectorial = ()
    float modulo1 = sqrt( PF_IMU[0]* PF_IMU[0] +  PF_IMU[1]* PF_IMU[1] +  PF_IMU[2]* PF_IMU[2]);
    float modulo2 = sqrt(pos_PF_IMU[0]*pos_PF_IMU[0] + pos_PF_IMU[1]*pos_PF_IMU[1] + pos_PF_IMU[2]*pos_PF_IMU[2]);
    angulo = degrees(acos(prodPunto/(modulo1*modulo2)));
   // println(angulo);
    
    if( aux <= 3)
    {
      ang_crudo[aux] =angulo;
      aux ++;
    }
    else
    {
      aux = 0;
      prom_ang = ( ang_crudo[0]+ ang_crudo[1]+ ang_crudo[2]+ ang_crudo[3])/4;
      promedio = floor(prom_ang);
      //println("angulo: "+ promedio);
    }
    
    // Cambiamos las flags para indicar que se espera una nueva carga de información
    dev1.loaded = false;
  }
  else
  {
    if(data.length >90)
    {
      data = subset(data,0,data.length-2);
      String message_wbb = new String( data );
      String []nums = split(message_wbb,",");
      float []vals = float(nums);
      x = map(vals[4],-15,15,0,width);
      y = map(-vals[5], -15,15,height,0);
    }
  }
}

//------------------------------------------------------------------------//


//------------------------------------------------------------------------//
void keyPressed()
{
  if (key == 'x')
  {grabar_pos = true;
  fijar_posicion = true;
  aux_pos = true;}
}
//------------------------------------------------------------------------//
