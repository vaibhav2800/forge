#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

/*
 * If this program calls the python script directly, for some reason doing:
 * setresuid(), setresgid() in this program then
 * 'chown gdm:gdm a.out && chmod ug+s a.out' to run the binary as user gdm
 * throws an error when the python script calls gconftool-2.
 *
 * However, running the binary with 'sudo -u gdm ./a.out [args]' works.
 * So this program will run as root and do 'sudo -u gdm script.py [args]'.
 *
 * gcc -Wall a.c && sudo chown root:root a.out && sudo chmod u+s a.out
 */

int main(int argc, char * argv[])
{
	const char *const sep = "/";
	const char *const file = "random-wallpaper.py";
	const int pathsize = 1024;
	char path[pathsize];

	char *const prefix_argv[] = {
		"dummy_sudo_argv0",
		"sudo",
		"-u",
		"gdm",
		path,
	};
	int prefix_argc = sizeof(prefix_argv) / sizeof(*prefix_argv);

	// drop argc[0] and add a NULL arg at the end
	int final_argc = prefix_argc + argc;
	char * final_argv[final_argc];

	int i;

	ssize_t path_len = readlink("/proc/self/exe", path, pathsize);
	if (path_len == -1) {
		perror("error during readlink");
		return 1;
	}
	if (path_len == pathsize) {
		fprintf(stderr, "readlink path too large\n");
		return 1;
	}

	path[path_len] = '\0';

	char * path_copy = strdup(path);
	if (!path_copy) {
		perror("error during strdup(path)");
		return 1;
	} else {
		char * dir = dirname(path_copy);
		strcpy(path, dir);
		free(path_copy);
	}

	if (strlen(path) + strlen(sep) + strlen(file) + 1 > pathsize) {
		fprintf(stderr, "final path to script too long\n");
		return 1;
	}
	strcat(path, sep);
	strcat(path, file);

	for (i = 0; i < prefix_argc; i++)
		final_argv[i] = prefix_argv[i];
	for (i = 1; i < argc; i++)
		final_argv[prefix_argc + i - 1] = argv[i];
	final_argv[prefix_argc + argc - 1] = NULL;

	// without this running "sudo ..." will ask for password
	if (setuid(geteuid())) {
		perror("setuid error");
		return 1;
	}

	execv("/usr/bin/sudo", final_argv);
	perror("execv error");

	return 0;
}
