#include <pthread.h>
#include <stdio.h>
#include <errno.h>

static int glob = 0;
static pthread_mutex_t mtx1 = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t mtx2 = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t mtx3 = PTHREAD_MUTEX_INITIALIZER;
static pthread_mutex_t mtx4 = PTHREAD_MUTEX_INITIALIZER;

static void *                  
threadFunc1(void *arg)
{
	int loops = *((int* )arg);
	int j,s;
	//for(j=0 ; j<loops ; j++){
		pthread_mutex_lock(&mtx1);
		pthread_mutex_lock(&mtx2);
		glob += 1;
		printf("in t1 glob = %d\n", glob);
		pthread_mutex_unlock(&mtx2);
		pthread_mutex_unlock(&mtx1);
	//}
	return NULL;
}

static void *                  
threadFunc2(void *arg)
{
	int loops = *((int* )arg);
	int j,s;
	//for(j=0 ; j<loops ; j++){
		pthread_mutex_lock(&mtx2);
		pthread_mutex_lock(&mtx3);
		glob += 1;
		printf("in t2 glob = %d\n", glob);
		pthread_mutex_unlock(&mtx3);
		pthread_mutex_unlock(&mtx2);
	//}
	return NULL;
}

static void *                  
threadFunc3(void *arg)
{
	int loops = *((int* )arg);
	int j,s;
	//for(j=0 ; j<loops ; j++){
		pthread_mutex_lock(&mtx3);
		pthread_mutex_lock(&mtx4);
		glob += 1;
		printf("in t1 glob = %d\n", glob);
		pthread_mutex_unlock(&mtx4);
		pthread_mutex_unlock(&mtx3);
	//}
	return NULL;
}

static void *                  
threadFunc4(void *arg)
{
	int loops = *((int* )arg);
	int j,s;
	//for(j=0 ; j<loops ; j++){
		pthread_mutex_lock(&mtx4);
		pthread_mutex_lock(&mtx1);
		glob += 1;
		printf("in t1 glob = %d\n", glob);
		pthread_mutex_unlock(&mtx1);
		pthread_mutex_unlock(&mtx4);
	//}
	return NULL;
}

int
main(int argc, char *argv[])
{
    pthread_t t1, t2 , t3 , t4;
    int loops, s;

    loops = 100000;

    s = pthread_create(&t1, NULL, threadFunc1, &loops);
   
    s = pthread_create(&t2, NULL, threadFunc2, &loops);

	s = pthread_create(&t3, NULL, threadFunc3, &loops);
	
	s = pthread_create(&t4, NULL, threadFunc4, &loops);
  
    printf("glob = %d\n", glob);
    return 0;
}















