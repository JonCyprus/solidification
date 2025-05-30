// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.28.0
// source: twobody_filepaths.sql

package database

import (
	"context"
	"time"

	"github.com/google/uuid"
)

const createTwoBodyFile = `-- name: CreateTwoBodyFile :one
INSERT INTO twobody_filepaths(run_id, category, timestep, filename, created_at, updated_at)
VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6
       ) RETURNING run_id, category, timestep, filename, created_at, updated_at
`

type CreateTwoBodyFileParams struct {
	RunID     uuid.UUID
	Category  string
	Timestep  int64
	Filename  string
	CreatedAt time.Time
	UpdatedAt time.Time
}

func (q *Queries) CreateTwoBodyFile(ctx context.Context, arg CreateTwoBodyFileParams) (TwobodyFilepath, error) {
	row := q.db.QueryRowContext(ctx, createTwoBodyFile,
		arg.RunID,
		arg.Category,
		arg.Timestep,
		arg.Filename,
		arg.CreatedAt,
		arg.UpdatedAt,
	)
	var i TwobodyFilepath
	err := row.Scan(
		&i.RunID,
		&i.Category,
		&i.Timestep,
		&i.Filename,
		&i.CreatedAt,
		&i.UpdatedAt,
	)
	return i, err
}

const wipeTwoBodyFiles = `-- name: WipeTwoBodyFiles :exec
DELETE FROM twobody_filepaths
`

func (q *Queries) WipeTwoBodyFiles(ctx context.Context) error {
	_, err := q.db.ExecContext(ctx, wipeTwoBodyFiles)
	return err
}
