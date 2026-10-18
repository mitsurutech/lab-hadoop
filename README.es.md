# Laboratorio de Hadoop HDFS y MapReduce con Docker Compose: poner un archivo en HDFS y contar sus palabras en una copia privada

[English](README.md) | [Français](README.fr.md) | [日本語](README.ja.md) | [Español](README.es.md)

[![check](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml/badge.svg)](https://github.com/mitsurutech/lab-hadoop/actions/workflows/check.yml)

Un **laboratorio de Hadoop** listo para usar en clase, de la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning), donde las escuelas y los centros dan a cada alumno sus propias bases de datos, contenedores y terminal en el navegador. Cada alumno recibe un pequeño **clúster de Hadoop** privado: **HDFS**, el sistema de archivos distribuido, con un NameNode y un DataNode, y **YARN** con un ResourceManager y un NodeManager para ejecutar trabajos de **MapReduce**. Los alumnos **ponen un archivo en HDFS, lo listan, lo leen de nuevo y ejecutan el contador de palabras incluido** sobre él, por HTTP con `curl` y en la página web del propio NameNode. Es una buena primera toma de contacto con el almacenamiento y el procesamiento de datos masivos en una unidad de datos, de nube o de sistemas distribuidos, sin instalar nada y sin riesgo para el equipo de nadie.

Es un solo archivo `docker-compose`, `compose.yaml`, que funciona igual en tu propio equipo que en la plataforma, donde cada alumno tiene una copia privada sin salida a internet.

## Qué hay

| Servicio | Imagen | Memoria | Qué es |
| --- | --- | --- | --- |
| `namenode` | [`apache/hadoop:3.4.1`](https://hub.docker.com/r/apache/hadoop) | 384 MB | el directorio de archivos de HDFS y dónde están sus bloques, con WebHDFS y la página web en el puerto 9870 |
| `datanode` | `apache/hadoop:3.4.1` | 256 MB | guarda los bloques de los archivos |
| `resourcemanager` | `apache/hadoop:3.4.1` | 384 MB | el planificador de YARN, con la lista de trabajos en el puerto 8088 |
| `nodemanager` | `apache/hadoop:3.4.1` | 512 MB | ejecuta las tareas de un trabajo |
| `client` | `apache/hadoop:3.4.1` | 320 MB | ejecuta el contador de palabras cuando el clúster está en marcha y se queda activo para poder lanzar un segundo con `docker exec` |

Son 1856 MB de límites, por debajo de los 2 GB que la plataforma da a una copia. Los cinco servicios usan una sola imagen, así que se descarga una vez. En reposo, una copia usa unos 820 MB, y en un equipo Intel o AMD normal está sana en aproximadamente un minuto, incluido el primer recuento de palabras. El primer arranque descarga la imagen (unos 1,2 GB comprimidos).

La imagen es la del propio proyecto Apache Hadoop, ejecutada sin modificar y fijada a una versión (nunca `latest`), de modo que el laboratorio no cambia a una clase de una lección a la siguiente. Aquí no se construye nada y nada de este repositorio se distribuye en ella. La configuración la escribe el punto de entrada de cada servicio a partir del archivo compose, así que no hay nada más que descargar. Los montones de memoria están reducidos al mínimo y el trabajo se ejecuta como un pequeño trabajo «uber», por eso una copia es pequeña, y por eso es un clúster para enseñar y no un lugar donde procesar datos reales.

## Usarlo en la plataforma

La [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning) da a cada alumno su propia copia de un laboratorio, en el navegador, con una terminal al lado.

**Para probarlo:** abre la [página de contenedores](https://mitsurutech.co.uk/es/container), busca este laboratorio en **Laboratorios de ejemplo** y pulsa Iniciar. No hace falta una cuenta para probar uno. La página del manual dedicada a él es [Laboratorio de Hadoop](https://mitsurutech.co.uk/es/help/lab-hadoop), y la lección **Hadoop Basics** lo recorre paso a paso.

**Para ponerlo como trabajo a una clase:**

1. En tu módulo, crea una tarea de tipo **Laboratorio** y elige **En un repositorio de GitHub**.
2. Indica `https://github.com/mitsurutech/lab-hadoop` con la rama `main`. El archivo compose es el predeterminado, `compose.yaml`. Haz antes un fork del repositorio si quieres cambiar el archivo.
3. Publica. La copia de cada alumno parte del commit que publicaste, así que un cambio posterior aquí no altera un laboratorio ya asignado.
4. Di en la tarea qué hay que entregar (consulta [Para profesores](#para-profesores)) y asígnala como cualquier otra tarea.

La [guía de laboratorios de contenedores](https://mitsurutech.co.uk/es/help/labs) del manual cubre el resto: qué puede decir un archivo compose, cuánta memoria recibe una copia y cómo abre, vigila y califica un profesor la copia de un alumno.

¿Aún no tienes una cuenta de centro? [El primer año es gratis](https://mitsurutech.co.uk/es/pricing) hasta 50 alumnos, y [registrarse](https://mitsurutech.co.uk/es/signup) solo pide una dirección de correo electrónico.

## Ejecutarlo en tu propio equipo

Necesitas Docker con el plugin Compose y unos 2 GB de memoria para dedicarle. El primer arranque descarga la imagen, que es grande.

```bash
docker compose -f compose.yaml -f local.yaml up
```

Abre <http://localhost:9870> para el NameNode y <http://localhost:8088> para el ResourceManager. El clúster arranca y luego ejecuta un recuento de palabras, que la primera vez tarda unos minutos. `local.yaml` solo publica esos dos puertos y solo en `127.0.0.1`, así que el laboratorio es accesible desde tu propio ordenador y desde ningún otro sitio. Páralo con `Ctrl-C` y elimínalo con `docker compose -f compose.yaml -f local.yaml down -v`.

La imagen se construye solo para procesadores Intel y AMD (`amd64`). En un Mac con Apple Silicon, Docker la ejecuta mediante emulación, lo que funciona pero tarda mucho más en arrancar.

## Paso a paso

La terminal del laboratorio no tiene el comando `hadoop`, así que usa **WebHDFS**, la interfaz HTTP de HDFS, con `curl`. Todas las direcciones empiezan por `http://namenode:9870/webhdfs/v1`.

1. **Mira el archivo que el clúster ha contado por ti.** `curl 'http://namenode:9870/webhdfs/v1/user/lab/input?op=LISTSTATUS'` lista la carpeta, y lo mismo en la página web del NameNode está en **Utilities, Browse the file system**. Cuando el clúster arrancó, un servicio ejecutó el contador de palabras de Hadoop sobre `/user/lab/input/sentence.txt` y dejó el resultado en `/user/lab/wordcount-out`.
2. **Lee el resultado.** `curl -L 'http://namenode:9870/webhdfs/v1/user/lab/wordcount-out/part-r-00000?op=OPEN'` imprime una línea por palabra, con la palabra y las veces que apareció. La `-L` importa: el NameNode responde con una redirección al DataNode que tiene los bytes.
3. **Pon un archivo tuyo en HDFS.** Crea una carpeta con `curl -X PUT 'http://namenode:9870/webhdfs/v1/user/lab/mine?op=MKDIRS&user.name=lab'` y escribe el archivo con `curl -L -X PUT -T mytext.txt 'http://namenode:9870/webhdfs/v1/user/lab/mine/mytext.txt?op=CREATE&user.name=lab'`. Escribir son en realidad dos peticiones, el NameNode eligiendo un DataNode y el DataNode recibiendo los bytes, que es precisamente el objetivo del ejercicio.
4. **Lístalo y léelo de nuevo** con `op=LISTSTATUS` y `op=OPEN`, como antes.
5. **Ejecuta MapReduce sobre él.** `docker exec client hadoop jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-3.4.1.jar wordcount /user/lab/mine /user/lab/mine-out` ejecuta el contador de palabras como un trabajo de YARN, y la página del ResourceManager, o `curl http://resourcemanager:8088/ws/v1/cluster/apps`, lo lista. Lee `/user/lab/mine-out/part-r-00000` como en el paso 2.

No se guarda nada cuando el laboratorio se detiene: HDFS guarda sus datos dentro de los contenedores y vuelve a empezar vacío, con el primer recuento de palabras hecho de nuevo. Aquí nada está protegido, se acepta cualquier nombre de usuario y los permisos están desactivados, lo cual está bien para una copia solo tuya y mal para un clúster real.

## Para profesores

Nada en este laboratorio se califica automáticamente. El alumno entrega pruebas y tú las calificas, como cualquier otro laboratorio.

**Pide pruebas en dos mitades.** Primero, la prueba del trabajo: la ruta del archivo que puso en HDFS, las líneas del recuento de palabras que MapReduce hizo con él y la página del ResourceManager o la salida de la lista de trabajos que muestre que el trabajo terminó. Segundo, la comprensión: qué guarda el NameNode y qué guarda el DataNode, por qué un archivo se lee con dos peticiones y por qué un clúster real guarda tres copias de cada bloque. Como cada alumno elige su propio texto, las respuestas son distintas y una copiada se nota.

**Dónde encaja en un curso.** Es adecuado para una primera toma de contacto con el almacenamiento distribuido y MapReduce en una unidad de datos, nube, big data o sistemas. Consulta la unidad de tu propio organismo de certificación para ver la redacción exacta; aquí no se cita ninguna.

**Quién ve qué.** Una copia es privada del alumno que la inició. Un miembro del personal que da el módulo puede abrirla para ver lo que ha hecho el alumno, y abrir el trabajo de un alumno queda anotado en el registro de accesos, que el alumno puede leer.

## Lo que no funciona en un laboratorio

El laboratorio no tiene salida a internet, así que no se puede descargar nada en él. Es un DataNode y un NodeManager, por lo que muestra cómo se organiza Hadoop pero no cómo sobrevive a la caída de una máquina ni cómo acelera un trabajo grande, y la replicación está fijada en uno. La página del navegador para el contenido de un archivo lleva al navegador al DataNode, que una copia no abre, así que el contenido de los archivos se lee con `curl`. Las páginas propias del NodeManager y del DataNode tampoco están abiertas. Ejecutar un trabajo necesita el comando `docker exec` en la terminal del laboratorio. No se guarda nada cuando el laboratorio se detiene. Hive, Spark y HBase no forman parte de él.

## Comprobar el laboratorio

`test/check.sh` arranca el laboratorio como lo hace el ejecutor de la plataforma con cada servicio (todas las capacidades retiradas, `no-new-privileges`, un límite de procesos, límites de memoria y sin salida a internet) y luego comprueba desde dentro de su red lo que promete esta página: cada servicio está sano, el recuento de palabras que ejecutó el clúster está en HDFS y WebHDFS lo lee, un archivo entra con dos peticiones y vuelve a salir, un trabajo de MapReduce del propio alumno se ejecuta y su resultado es correcto, y el ResourceManager lista los trabajos. Necesita Docker y se ejecuta en cada push, que es la insignia de la parte superior.

```bash
test/check.sh
```

## Versiones y licencias

[Apache Hadoop](https://hadoop.apache.org) tiene licencia Apache 2.0. Se ejecuta sin modificar desde su propia imagen pública, `apache/hadoop:3.4.1`, y no se distribuye aquí.

La aplicación que contiene conserva la licencia de su propio proyecto.

## Licencia

Esta obra está bajo licencia [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/). Puedes compartirla y adaptarla para aprender y enseñar, si citas a Mitsuru Technologies Ltd, no la usas comercialmente y compartes lo que hagas con ella bajo la misma licencia. El texto completo está en el archivo `LICENSE`.

## Acerca de

Hecho por [Mitsuru Technologies](https://mitsurutech.co.uk) para la [plataforma de aprendizaje MitsuruTech](https://mitsurutech.co.uk/es/learning): Python, Java, Go, Node, SQL y Linux en el navegador para escuelas y centros, con laboratorios de contenedores, aplicaciones web desplegadas desde GitHub y cuestionarios que se califican solos. Prueba código sin cuenta en el [entorno de pruebas](https://mitsurutech.co.uk/es/playground). El [manual](https://mitsurutech.co.uk/es/help/labs) lista todos los laboratorios.

Más laboratorios del mismo sitio: [lab-juice-shop](https://github.com/mitsurutech/lab-juice-shop), [lab-dvwa](https://github.com/mitsurutech/lab-dvwa), [lab-webgoat](https://github.com/mitsurutech/lab-webgoat), [lab-mysql-phpmyadmin](https://github.com/mitsurutech/lab-mysql-phpmyadmin), [lab-git-gitea](https://github.com/mitsurutech/lab-git-gitea), [lab-observability](https://github.com/mitsurutech/lab-observability) y [lab-sample](https://github.com/mitsurutech/lab-sample).
