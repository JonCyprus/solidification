-- name: CreateTwoBodyFile :one
INSERT INTO twobody_filepaths(run_id, category, timestep, filename, created_at, updated_at)
VALUES (
        $1,
        $2,
        $3,
        $4,
        $5,
        $6
       ) RETURNING *;

-- name: WipeTwoBodyFiles :exec
DELETE FROM twobody_filepaths;