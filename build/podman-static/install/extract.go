package install

import (
	"os"

	seekable "github.com/SaveTheRbtz/zstd-seekable-format-go/pkg"
	"github.com/klauspost/compress/zstd"
	"github.com/ngicks/go-fsys-helper/tarfs"
)

// extractArtifact expands the seekable zstd tar at tarPath into destDir. The
// seekable reader exposes the decompressed tar as an io.ReaderAt, tarfs presents
// that as an fs.FS (HandleSymlink keeps the generator symlinks), and os.CopyFS
// materializes it. destDir is removed first because os.CopyFS opens files with
// O_EXCL and refuses to overwrite an existing tree.
func extractArtifact(tarPath, destDir string) (err error) {
	f, err := os.Open(tarPath)
	if err != nil {
		return err
	}
	defer func() {
		if cerr := f.Close(); err == nil {
			err = cerr
		}
	}()

	dec, err := zstd.NewReader(nil)
	if err != nil {
		return err
	}
	defer dec.Close()

	sr, err := seekable.NewReader(f, dec)
	if err != nil {
		return err
	}
	defer func() {
		if cerr := sr.Close(); err == nil {
			err = cerr
		}
	}()

	fsys, err := tarfs.New(sr, &tarfs.FsOption{HandleSymlink: true})
	if err != nil {
		return err
	}
	if err := os.RemoveAll(destDir); err != nil {
		return err
	}
	return os.CopyFS(destDir, fsys)
}
