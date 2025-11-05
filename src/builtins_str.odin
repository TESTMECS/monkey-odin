package monkey
import "core:crypto/hash"
import "core:fmt"
import "core:strings"

b_hash :: proc(e: ^Evaluator, args: [dynamic]ObjectBase) -> (ObjectBase, bool) {
	usage := `
				"Hash a string">>
				hash(str)
				$ str
				Usage: hash("monkey")=>>123456789<<
				`


	if len(args) != 1 {
		return eval_new_error(
				e,
				"'hash' function error: wrong number of arguments, wants='1', got='%d'.%s",
				len(args),
				usage,
			),
			false
	}

	#partial switch arg in args[0] {
	case string:
		s_copy := strings.clone(arg, e.varena)
		digest := hash.hash_string(hash.Algorithm.SHA256, s_copy)
		sb := strings.builder_make(e.varena)
		for b in digest {
			fmt.sbprintf(&sb, "%02x", b)
		}
		hex_str := strings.to_string(sb)
		return fmt.tprintfln("SHA-256(\"%s\") = %x", s_copy, hex_str), true
	}

	return eval_new_error(
			e,
			"'hash' function error: not supported for argument of type '%v'.%s",
			ObjectType(args[0]),
			usage,
		),
		false
}

