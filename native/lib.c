#include <stdbool.h>
#include <string.h>
#include <erl_nif.h>


static int load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
static void unload(ErlNifEnv *env, void *priv);
static int reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM info);
static int upgrade(ErlNifEnv *env, void **priv, void **old_priv, ERL_NIF_TERM info);

int enif_get_long_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, long **vec, size_t *vec_l);
//int enif_get_long_vec_from_list_g(ErlNifEnv *env, ERL_NIF_TERM list, long **vec, size_t *vec_l);

ERL_NIF_TERM enif_make_list_from_long_vec(ErlNifEnv *env, const long *vec, const size_t vec_l);
int enif_get_range(ErlNifEnv *env, ERL_NIF_TERM range, long *first, long *last);

int enif_get_double_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l);
ERL_NIF_TERM enif_make_list_from_double_vec(ErlNifEnv *env, const double *vec, const size_t vec_l);

int enif_get_double_vec_from_number_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l);

static ERL_NIF_TERM func(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);
// static ERL_NIF_TERM func_g(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);
static ERL_NIF_TERM range_to_list(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

static ERL_NIF_TERM enum_map_mult_2(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

static ERL_NIF_TERM number_list_to_double_list(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

static ERL_NIF_TERM enum_map_logistic_map(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

static ERL_NIF_TERM enum_map_logistic_map(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

static ERL_NIF_TERM chunk_every(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[]);

static
ErlNifFunc nif_funcs[] =
{
	// {erl_function_name, erl_function_arity, c_function}
	{"range_to_list", 1, range_to_list},
	{"func", 1, func},
	// {"func_g", 1, func_g},
	{"enum_map_mult_2", 1, enum_map_mult_2},
	{"number_list_to_double_list", 1, number_list_to_double_list},
	{"enum_map_logistic_map", 3, enum_map_logistic_map},
	{"chunk_every", 2, chunk_every},
};

ERL_NIF_INIT(Elixir.VecSample, nif_funcs, &load, &reload, &upgrade, &unload)

const int fail = 0;
const int success = 1;
const int empty = 0;
const size_t cache_line_size = 64;
const size_t size_t_max = -1;
const size_t init_size_long = cache_line_size / sizeof(long);
const size_t init_size_double = cache_line_size / sizeof(double);
const size_t size_t_highest_bit = ~(size_t_max >> 1);

#define loop_vectorize_width 4

static ERL_NIF_TERM ok_atom;
static ERL_NIF_TERM error_atom;
static ERL_NIF_TERM struct_atom;
static ERL_NIF_TERM range_atom;
static ERL_NIF_TERM first_atom;
static ERL_NIF_TERM last_atom;


static void
init_nif_vec(ErlNifEnv *env)
{
	ok_atom = enif_make_atom(env, "ok");
	error_atom = enif_make_atom(env, "error");
	struct_atom = enif_make_atom(env, "__struct__");
	range_atom = enif_make_atom(env, "Range");
	first_atom = enif_make_atom(env, "first");
	last_atom = enif_make_atom(env, "last");
}

static ERL_NIF_TERM
func(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
	if (__builtin_expect((argc != 1), false)) {
		return enif_make_badarg(env);
	}

	long *vec;
	size_t vec_l;
	if (__builtin_expect((enif_get_long_vec_from_list(env, argv[0], &vec, &vec_l) == fail), false)) {
		return enif_make_badarg(env);
	}
	return enif_make_list_from_long_vec(env, vec, vec_l);
}

/*
static ERL_NIF_TERM
func_g(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
	if (__builtin_expect((argc != 1), false)) {
		return enif_make_badarg(env);
	}

	long *vec;
	size_t vec_l;
	if (__builtin_expect((enif_get_long_vec_from_list_g(env, argv[0], &vec, &vec_l) == fail), false)) {
		return enif_make_badarg(env);
	}
	return enif_make_list_from_long_vec(env, vec, vec_l);
}
*/
/*
int
enif_get_long_vec_from_list_g(ErlNifEnv *env, ERL_NIF_TERM list, long **vec, size_t *vec_l)
{
	ERL_NIF_TERM head, tail;

	if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == fail),
											 true)) {
		if (__builtin_expect((enif_is_empty_list(env, list) == success), false)) {
			*vec_l = empty;
			*vec = NULL;
			return success;
		}
		return fail;
	}
	size_t n = init_size_long;
	size_t nn = cache_line_size;
	long *t = (long *)enif_alloc(nn);
	if (__builtin_expect((t == NULL), false)) {
		return fail;
	}

	size_t i = 0;
	while (true) {
		if (__builtin_expect((enif_get_int64(env, head, &t[i]) == fail), false)) {
			enif_free(t);
			return fail;
		}
		i++;
		if (__builtin_expect(
					(enif_get_list_cell(env, tail, &head, &tail) == fail), false)) {
			*vec_l = i;
			*vec = t;
			return success;
		}
		if (__builtin_expect((i >= n), false)) {
			size_t old_nn = nn;
			if (__builtin_expect(((nn & size_t_highest_bit) == 0), true)) {
				nn <<= 1;
				n <<= 1;
			} else {
				nn = size_t_max;
				n = nn / sizeof(long);
			}
			long *new_t = (long *)enif_alloc(nn);
			if (__builtin_expect((new_t == NULL), false)) {
				enif_free(t);
				return fail;
			}
			memcpy(new_t, t, old_nn);
			enif_free(t);
			t = new_t;
		}
	}
}
*/

int
enif_get_long_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, long **vec, size_t *vec_l)
{
	ERL_NIF_TERM head, tail;

	if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == fail),
											 true)) {
		if (__builtin_expect((enif_is_empty_list(env, list) == success), true)) {
			*vec_l = empty;
			*vec = NULL;
			return success;
		}
		return fail;
	}
	size_t n = init_size_long;
	size_t nn = cache_line_size;
	long *t = (long *)enif_alloc(nn);
	if (__builtin_expect((t == NULL), false)) {
		return fail;
	}

	size_t i = 0;
	ERL_NIF_TERM tmp[loop_vectorize_width];
	int tmp_r[loop_vectorize_width];
	while (true) {
#pragma clang loop vectorize(disable)
		for (size_t count = 0; count < loop_vectorize_width; count++) {
			tmp[count] = head;
			if (__builtin_expect(
							(enif_get_list_cell(env, tail, &head, &tail) == fail), false)) {
				for (size_t c = 0; c <= count; c++) {
					tmp_r[c] = enif_get_int64(env, tmp[c], &t[i++]);
				}
				int acc = true;
#pragma clang loop vectorize(enable)
				for (size_t c = 0; c <= count; c++) {
					acc &= (tmp_r[c] == success);
				}
				if (__builtin_expect((acc == false), false)) {
					enif_free(t);
					return fail;
				}

				*vec_l = i;
				*vec = t;
				return success;
			}
		}
		if (__builtin_expect((i > size_t_max - loop_vectorize_width), false)) {
			enif_free(t);
			return fail;
		}
		if (__builtin_expect((i + loop_vectorize_width > n), false)) {
			size_t old_nn = nn;
			if (__builtin_expect(((nn & size_t_highest_bit) == 0), true)) {
				nn <<= 1;
				n <<= 1;
			} else {
				nn = size_t_max;
				n = nn / sizeof(long);
			}
			long *new_t = (long *)enif_alloc(nn);
			if(__builtin_expect((new_t == NULL), false)) {
				enif_free(t);
				return fail;
			}
			memcpy(new_t, t, old_nn);
			enif_free(t);
			t = new_t;
		}
#pragma clang loop vectorize(enable) unroll(enable)
		for (size_t count = 0; count < loop_vectorize_width; count++) {
			tmp_r[count] = enif_get_int64(env, tmp[count], &t[i + count]);
		}
		int acc = true;
#pragma clang loop vectorize(enable) unroll(enable)
		for (size_t count = 0; count < loop_vectorize_width; count++) {
			acc &= (tmp_r[count] == success);
		}
		if (__builtin_expect((acc == false), false)) {
			enif_free(t);
			return fail;
		}
		i += loop_vectorize_width;
	}
}

int
enif_get_double_vec_from_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l)
{
	ERL_NIF_TERM head, tail;

	if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == fail),
											 true)) {
		if (__builtin_expect((enif_is_empty_list(env, list) == success), true)) {
			*vec_l = empty;
			*vec = NULL;
			return success;
		}
		return fail;
	}
	size_t n = init_size_long;
	size_t nn = cache_line_size;
	double *t = (double *)enif_alloc(nn);
	if (__builtin_expect((t == NULL), false)) {
		return fail;
	}

	size_t i = 0;
	ERL_NIF_TERM tmp[loop_vectorize_width];
	int tmp_r[loop_vectorize_width];
	while (true) {
#pragma clang loop vectorize(disable)
		for (size_t count = 0; count < loop_vectorize_width; count++) {
			tmp[count] = head;
			if (__builtin_expect(
							(enif_get_list_cell(env, tail, &head, &tail) == fail), false)) {
				for (size_t c = 0; c <= count; c++) {
					tmp_r[c] = enif_get_double(env, tmp[c], &t[i++]);
				}
				int acc = true;
#pragma clang loop vectorize(enable)
				for (size_t c = 0; c <= count; c++) {
					acc &= (tmp_r[c] == success);
				}
				if (__builtin_expect((acc == false), false)) {
					enif_free(t);
					return fail;
				}

				*vec_l = i;
				*vec = t;
				return success;
			}
		}
		if (__builtin_expect((i > size_t_max - loop_vectorize_width), false)) {
			enif_free(t);
			return fail;
		}
		if (__builtin_expect((i + loop_vectorize_width > n), false)) {
			size_t old_nn = nn;
			if (__builtin_expect(((nn & size_t_highest_bit) == 0), true)) {
				nn <<= 1;
				n <<= 1;
			} else {
				nn = size_t_max;
				n = nn / sizeof(long);
			}
			double *new_t = (double *)enif_alloc(nn);
			if(__builtin_expect((new_t == NULL), false)) {
				enif_free(t);
				return fail;
			}
			memcpy(new_t, t, old_nn);
			enif_free(t);
			t = new_t;
		}
#pragma clang loop vectorize(enable) unroll(enable)
		for (size_t count = 0; count < loop_vectorize_width; count++) {
			tmp_r[count] = enif_get_double(env, tmp[count], &t[i + count]);
		}
		int acc = true;
#pragma clang loop vectorize(enable) unroll(enable)
		for (size_t count = 0; count < loop_vectorize_width; count++) {
			acc &= (tmp_r[count] == success);
		}
		if (__builtin_expect((acc == false), false)) {
			enif_free(t);
			return fail;
		}
		i += loop_vectorize_width;
	}
}

ERL_NIF_TERM
enif_make_list_from_long_vec(ErlNifEnv *env, const long *vec, const size_t vec_l)
{
	ERL_NIF_TERM list = enif_make_list(env, 0);
	for(size_t i = vec_l; i > 0; i--) {
		ERL_NIF_TERM tail = list;
		ERL_NIF_TERM head = enif_make_int64(env, vec[i - 1]);
		list = enif_make_list_cell(env, head, tail);
	}
	return list;
}

ERL_NIF_TERM
enif_make_list_from_double_vec(ErlNifEnv *env, const double *vec, const size_t vec_l)
{
	ERL_NIF_TERM list = enif_make_list(env, 0);
	for(size_t i = vec_l; i > 0; i--) {
		ERL_NIF_TERM tail = list;
		ERL_NIF_TERM head = enif_make_double(env, vec[i - 1]);
		list = enif_make_list_cell(env, head, tail);
	}
	return list;
}

int
enif_get_range(ErlNifEnv *env, ERL_NIF_TERM range, long *first, long *last)
{
	ERL_NIF_TERM struct_name;
	if (__builtin_expect((enif_get_map_value(env, range, struct_atom, &struct_name) == fail), false)) {
		return fail;
	}
	if(__builtin_expect(enif_is_identical(struct_name, range_atom), false)) {
		return fail;
	}
	ERL_NIF_TERM first_term, last_term;
	if(__builtin_expect((enif_get_map_value(env, range, first_atom, &first_term) == fail), false)) {
		return fail;
	}
	if(__builtin_expect((enif_get_map_value(env, range, last_atom, &last_term) == fail), false)) {
		return fail;
	}
	if(__builtin_expect((enif_get_int64(env, first_term, first) == fail), false)) {
		return fail;
	}
	if(__builtin_expect((enif_get_int64(env, last_term, last) == fail), false)) {
		return fail;
	}
	return success;
}

static ERL_NIF_TERM
range_to_list(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
	long first, last;
	if (__builtin_expect((argc != 1), false)) {
		return enif_make_badarg(env);
	}
	if (__builtin_expect((enif_get_range(env, argv[0], &first, &last) == fail), false)) {
		return enif_make_badarg(env);
	}
	ERL_NIF_TERM list = enif_make_list(env, 0);
	for(long i = last; i >= first; i--) {
		ERL_NIF_TERM tail = list;
		ERL_NIF_TERM head = enif_make_int64(env, i);
		list = enif_make_list_cell(env, head, tail);
	}
	return list;
}

static ERL_NIF_TERM
enum_map_mult_2(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
	if (__builtin_expect((argc != 1), false)) {
		return enif_make_badarg(env);
	}
	long *vec_long;
	size_t vec_l;
	double *vec_double;
	if (__builtin_expect((enif_get_long_vec_from_list(env, argv[0], &vec_long, &vec_l) == fail), false)) {
		if (__builtin_expect((enif_get_double_vec_from_list(env, argv[0], &vec_double, &vec_l) == fail), false)) {
			return enif_make_badarg(env);
		}
#pragma clang loop vectorize_width(loop_vectorize_width)
		for(size_t i = 0; i < vec_l; i++) {
			vec_double[i] *= 2.0;
		}
		return enif_make_list_from_double_vec(env, vec_double, vec_l);
	}
#pragma clang loop vectorize_width(loop_vectorize_width)
	for(size_t i = 0; i < vec_l; i++) {
		vec_long[i] *= 2;
	}
	return enif_make_list_from_long_vec(env, vec_long, vec_l);
}

int
enif_get_double_vec_from_number_list(ErlNifEnv *env, ERL_NIF_TERM list, double **vec, size_t *vec_l)
{
	ERL_NIF_TERM head, tail;

	if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == fail),
											 true)) {
		if (__builtin_expect((enif_is_empty_list(env, list) == success), true)) {
			*vec_l = empty;
			*vec = NULL;
			return success;
		}
		return fail;
	}
	size_t n = init_size_long;
	size_t nn = cache_line_size;
	double *t = (double *)enif_alloc(nn);
	if (__builtin_expect((t == NULL), false)) {
		return fail;
	}

	size_t i = 0;
	while (true) {
		if (__builtin_expect((enif_get_double(env, head, &t[i]) == fail), false)) {
			long tmp;
			if (__builtin_expect((enif_get_int64(env, head, &tmp) == fail), false)) {
				enif_free(t);
				return fail;
			}
			t[i] = (double)tmp;
		}
		i++;
		if (__builtin_expect(
					(enif_get_list_cell(env, tail, &head, &tail) == fail), false)) {
			*vec_l = i;
			*vec = t;
			return success;
		}
		if (__builtin_expect((i >= n), false)) {
			size_t old_nn = nn;
			if (__builtin_expect(((nn & size_t_highest_bit) == 0), true)) {
				nn <<= 1;
				n <<= 1;
			} else {
				nn = size_t_max;
				n = nn / sizeof(long);
			}
			double *new_t = (double *)enif_alloc(nn);
			if (__builtin_expect((new_t == NULL), false)) {
				enif_free(t);
				return fail;
			}
			memcpy(new_t, t, old_nn);
			enif_free(t);
			t = new_t;
		}
	}
}

static ERL_NIF_TERM
number_list_to_double_list(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
	if (__builtin_expect((argc != 1), false)) {
		return enif_make_badarg(env);
	}

	double *vec;
	size_t vec_l;
	if (__builtin_expect((enif_get_double_vec_from_number_list(env, argv[0], &vec, &vec_l) == fail), false)) {
		return enif_make_badarg(env);
	}
	return enif_make_list_from_double_vec(env, vec, vec_l);
}

static ERL_NIF_TERM
enum_map_logistic_map(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
	if (__builtin_expect((argc != 3), false)) {
		return enif_make_badarg(env);
	}
	long *vec, p, mu;
	size_t vec_l;
	if (__builtin_expect((enif_get_long_vec_from_list(env, argv[0], &vec, &vec_l) == fail), false)) {
		return enif_make_badarg(env);
	}
	if (__builtin_expect((enif_get_int64(env, argv[1], &p) == fail), false)) {
		return enif_make_badarg(env);
	}
	if (__builtin_expect((enif_get_int64(env, argv[2], &mu) == fail), false)) {
		return enif_make_badarg(env);
	}
#pragma clang loop vectorize_width(loop_vectorize_width)
	for(size_t i = 0; i < vec_l; i++) {
#pragma clang loop unroll(enable)
		for(int j = 0; j < 10; j++) {
			vec[i] = (mu * vec[i] * (vec[i] + 1)) % p;
		}
	}
	return enif_make_list_from_long_vec(env, vec, vec_l);
}

static ERL_NIF_TERM
chunk_every(ErlNifEnv *env, int argc, const ERL_NIF_TERM argv[])
{
	if (__builtin_expect((argc != 2), false)) {
		return enif_make_badarg(env);
	}
	unsigned long c;
	if (__builtin_expect((enif_get_uint64(env, argv[1], &c) == fail), false)) {
		return enif_make_badarg(env);
	}
	size_t count = (size_t)c;
	if(count > size_t_max / sizeof(ERL_NIF_TERM)) {
		return enif_make_badarg(env);
	}
	long first, last;
	if(__builtin_expect((enif_get_range(env, argv[0], &first, &last) == success), false)) {
		if(__builtin_expect((first == last), false)) {
			ERL_NIF_TERM value = enif_make_int64(env, first);
			return enif_make_list1(env, enif_make_list1(env, value));
		}
		size_t n = cache_line_size / sizeof(ERL_NIF_TERM);
		size_t nn = cache_line_size;
		ERL_NIF_TERM *ll = (ERL_NIF_TERM *)enif_alloc(nn);
		if(__builtin_expect(ll == NULL, false)) {
			return enif_make_badarg(env);
		}
		size_t li = 0;
		ERL_NIF_TERM *t = (ERL_NIF_TERM *)enif_alloc(count * sizeof(ERL_NIF_TERM));
		if(__builtin_expect(t == NULL, false)) {
			enif_free(ll);
			return enif_make_badarg(env);
		}
		if(__builtin_expect((first < last), true)) {
			unsigned long c = 0;
			for(long i = first; i <= last; i++) {
				if(c >= count) {
					ERL_NIF_TERM l = enif_make_list(env, 0);
					for(; c > 0; c--) {
						l = enif_make_list_cell(env, t[c - 1], l);
					}
					ll[li++] = l;
					if (__builtin_expect((li >= n), false)) {
						size_t old_nn = nn;
						if (__builtin_expect(((nn & size_t_highest_bit) == 0), true)) {
							nn <<= 1;
							n <<= 1;
						} else {
							nn = size_t_max;
							n = nn / sizeof(ERL_NIF_TERM);
						}
						ERL_NIF_TERM *new_ll = (ERL_NIF_TERM *)enif_alloc(nn);
						if (__builtin_expect((new_ll == NULL), false)) {
							enif_free(ll);
							enif_free(t);
							return enif_make_badarg(env);
						}
						memcpy(new_ll, ll, old_nn);
						enif_free(ll);
						ll = new_ll;
					}
				}
				t[c++] = enif_make_int64(env, i);
			}
			ERL_NIF_TERM l = enif_make_list(env, 0);
			for(; c > 0; c--) {
				l = enif_make_list_cell(env, t[c - 1], l);
			}
			ll[li++] = l;
			l = enif_make_list(env, 0);
			for(; li > 0; li--) {
				l = enif_make_list_cell(env, ll[li - 1], l);
			}
			enif_free(ll);
			enif_free(t);
			return l;
		} else {
			unsigned long c = 0;
			for(long i = first; i >= last; i--) {
				if(c >= count) {
					ERL_NIF_TERM l = enif_make_list(env, 0);
					for(; c > 0; c--) {
						l = enif_make_list_cell(env, t[c - 1], l);
					}
					ll[li++] = l;
					if (__builtin_expect((li >= n), false)) {
						size_t old_nn = nn;
						if (__builtin_expect(((nn & size_t_highest_bit) == 0), true)) {
							nn <<= 1;
							n <<= 1;
						} else {
							nn = size_t_max;
							n = nn / sizeof(ERL_NIF_TERM);
						}
						ERL_NIF_TERM *new_ll = (ERL_NIF_TERM *)enif_alloc(nn);
						if (__builtin_expect((new_ll == NULL), false)) {
							enif_free(ll);
							enif_free(t);
							return enif_make_badarg(env);
						}
						memcpy(new_ll, ll, old_nn);
						enif_free(ll);
						ll = new_ll;
					}
				}
				t[c++] = enif_make_int64(env, i);
			}
			ERL_NIF_TERM l = enif_make_list(env, 0);
			for(; c > 0; c--) {
				l = enif_make_list_cell(env, t[c - 1], l);
			}
			ll[li++] = l;
			l = enif_make_list(env, 0);
			for(; li > 0; li--) {
				l = enif_make_list_cell(env, ll[li - 1], l);
			}
			enif_free(ll);
			enif_free(t);
			return l;
		}
	}
	ERL_NIF_TERM list, head, tail;
	list = argv[0];
	if (__builtin_expect((enif_get_list_cell(env, list, &head, &tail) == fail), true)) {
		if (__builtin_expect((enif_is_empty_list(env, list) == success), true)) {
			return list;
		} else {
			return enif_make_badarg(env);
		}
	}
	size_t n = cache_line_size / sizeof(ERL_NIF_TERM);
	size_t nn = cache_line_size;
	ERL_NIF_TERM *ll = (ERL_NIF_TERM *)enif_alloc(nn);
	if(__builtin_expect(ll == NULL, false)) {
		return enif_make_badarg(env);
	}
	size_t li = 0;
	ERL_NIF_TERM *t = (ERL_NIF_TERM *)enif_alloc(count * sizeof(ERL_NIF_TERM));
	if(__builtin_expect(t == NULL, false)) {
		enif_free(ll);
		return enif_make_badarg(env);
	}
	while(true) {
		for(size_t i = 0; i < count; i++) {
			t[i] = head;
			if (__builtin_expect((enif_get_list_cell(env, tail, &head, &tail) == fail), false)) {
				ERL_NIF_TERM l = enif_make_list(env, 0);
				i++;
				for(; i > 0; i--) {
					l = enif_make_list_cell(env, t[i - 1], l);
				}
				ll[li++] = l;
				l = enif_make_list(env, 0);
				for(; li > 0; li--) {
					l = enif_make_list_cell(env, ll[li - 1], l);
				}
				enif_free(ll);
				enif_free(t);
				return l;
			}
		}
		ERL_NIF_TERM l = enif_make_list(env, 0);
		for(size_t i = count; i > 0; i--) {
			l = enif_make_list_cell(env, t[i - 1], l);
		}
		ll[li++] = l;
		if (__builtin_expect((li >= n), false)) {
			size_t old_nn = nn;
			if (__builtin_expect(((nn & size_t_highest_bit) == 0), true)) {
				nn <<= 1;
				n <<= 1;
			} else {
				nn = size_t_max;
				n = nn / sizeof(ERL_NIF_TERM);
			}
			ERL_NIF_TERM *new_ll = (ERL_NIF_TERM *)enif_alloc(nn);
			if (__builtin_expect((new_ll == NULL), false)) {
				enif_free(ll);
				enif_free(t);
				return enif_make_badarg(env);
			}
			memcpy(new_ll, ll, old_nn);
			enif_free(ll);
			ll = new_ll;
		}
	}
}

static int
load(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
	init_nif_vec(env);
	return 0;
}

static void
unload(ErlNifEnv *env, void *priv)
{
}

static int
reload(ErlNifEnv *env, void **priv, ERL_NIF_TERM info)
{
	return 0;
}

static int
upgrade(ErlNifEnv *env, void **priv, void **old_priv, ERL_NIF_TERM info)
{
	return load(env, priv, info);
}
