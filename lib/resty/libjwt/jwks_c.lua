local ffi = require("ffi")

ffi.cdef [[
typedef struct jwt_checker jwt_checker_t;
jwt_checker_t *jwt_checker_new(void);
int jwt_checker_verify(jwt_checker_t *checker, const char *token);
const char *jwt_checker_error_msg(const jwt_checker_t *checker);

typedef enum {
    JWT_ALG_NONE = 0,	/**< No signature */
    JWT_ALG_HS256,		/**< HMAC using SHA-256 */
    JWT_ALG_HS384,		/**< HMAC using SHA-384 */
    JWT_ALG_HS512,		/**< HMAC using SHA-512 */
    JWT_ALG_RS256,		/**< RSASSA-PKCS1-v1_5 using SHA-256 */
    JWT_ALG_RS384,		/**< RSASSA-PKCS1-v1_5 using SHA-384 */
    JWT_ALG_RS512,		/**< RSASSA-PKCS1-v1_5 using SHA-512 */
    JWT_ALG_ES256,		/**< ECDSA using P-256 and SHA-256 */
    JWT_ALG_ES384,		/**< ECDSA using P-384 and SHA-384 */
    JWT_ALG_ES512,		/**< ECDSA using P-521 and SHA-512 */
    JWT_ALG_PS256,		/**< RSASSA-PSS using SHA-256 and MGF1 with SHA-256 */
    JWT_ALG_PS384,		/**< RSASSA-PSS using SHA-384 and MGF1 with SHA-384 */
    JWT_ALG_PS512,		/**< RSASSA-PSS using SHA-512 and MGF1 with SHA-512 */
    JWT_ALG_ES256K,		/**< ECDSA using secp256k1 and SHA-256 */
    JWT_ALG_EDDSA,		/**< EdDSA using Ed25519 */
    JWT_ALG_INVAL,		/**< An invalid algorithm from the caller or the token */
} jwt_alg_t;

typedef struct jwk_item jwk_item_t;

int jwt_checker_setkey(jwt_checker_t *checker, const jwt_alg_t alg, const jwk_item_t *key);
typedef struct jwk_set jwk_set_t;
jwk_set_t *jwks_create(const char *jwk_json_str);
const jwk_item_t *jwks_item_get(const jwk_set_t *jwk_set, size_t index);
jwk_item_t *jwks_find_bykid(jwk_set_t *jwk_set, const char *kid);
jwt_alg_t jwks_item_alg(const jwk_item_t *item);
]]

local libjwt = ffi.load("libjwt");

return libjwt
