
CREATE TABLE IF NOT EXISTS acme.films (
    FilmsUUID UUID DEFAULT uuid_v4()::UUID PRIMARY KEY,
    films JSONB
);

CREATE INDEX IF NOT EXISTS filmsIdx ON acme.films USING GIN (films);
