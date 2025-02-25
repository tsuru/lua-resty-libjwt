package replace_test

import (
	"fmt"
	"os"

	"regexp"
	"strings"
)

func ReplaceNginxConfig(pathFile string, newPaths []string) (file []byte, err error) {
	content, err := os.ReadFile(pathFile)
	if err != nil {
		return nil, err
	}
	config := string(content)
	re := regexp.MustCompile(`\["jwks_files"\]\s*=\s*\{[^}]*\}`)
	newValue := fmt.Sprintf(`["jwks_files"] = {%s}`, strings.Join(newPaths, `, `))
	modifiedConfig := re.ReplaceAllString(config, newValue)
	return []byte(modifiedConfig), nil
}
