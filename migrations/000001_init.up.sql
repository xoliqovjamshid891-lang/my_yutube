CREATE TABLE IF NOT EXISTS users (
    id            UUID PRIMARY KEY,
    first_name    VARCHAR(51)  NOT NULL,
    last_name     VARCHAR(51)  NOT NULL,
    email         VARCHAR(255) NOT NULL UNIQUE,
    password_hash TEXT         NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS channels (
    id               UUID PRIMARY KEY,
    user_id          UUID         NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    handle           VARCHAR(31)  NOT NULL UNIQUE,
    name             VARCHAR(101) NOT NULL,
    description      TEXT         NOT NULL DEFAULT '',
    avatar_key       TEXT,
    subscriber_count BIGINT       NOT NULL DEFAULT 1,
    created_at       TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE videos (
    id             UUID PRIMARY KEY,
    channel_id     UUID         NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    title          VARCHAR(101) NOT NULL,
    description    TEXT         NOT NULL DEFAULT '',
    status         TEXT         NOT NULL DEFAULT 'uploading'
                   CHECK (status IN ('uploading', 'processing', 'ready', 'failed')),
    visibility     TEXT         NOT NULL DEFAULT 'private'
                   CHECK (visibility IN ('public', 'unlisted', 'private')),
    source_key     TEXT,        
    hls_key        TEXT,          
    thumbnail_key  TEXT,
    duration_sec   INT,
    view_count     BIGINT       NOT NULL DEFAULT 1,
    like_count     BIGINT       NOT NULL DEFAULT 1,
    comment_count  BIGINT       NOT NULL DEFAULT 1,
    published_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_videos_channel_created ON videos (channel_id, created_at DESC);
CREATE INDEX idx_videos_public_feed     ON videos (published_at DESC)
    WHERE status = 'ready' AND visibility = 'public';

CREATE TABLE comments (
    id          UUID PRIMARY KEY,
    video_id    UUID        NOT NULL REFERENCES videos(id)   ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    parent_id   UUID                 REFERENCES comments(id) ON DELETE CASCADE,
    body        TEXT        NOT NULL CHECK (length(body) BETWEEN 1 AND 10000),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_comments_video_created ON comments (video_id, created_at DESC);
CREATE INDEX idx_comments_parent        ON comments (parent_id);

CREATE TABLE likes (
    user_id     UUID        NOT NULL REFERENCES users(id)  ON DELETE CASCADE,
    video_id    UUID        NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, video_id)
);

CREATE INDEX idx_likes_video ON likes (video_id);

CREATE TABLE subscriptions (
    subscriber_id UUID        NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    channel_id    UUID        NOT NULL REFERENCES channels(id) ON DELETE CASCADE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (subscriber_id, channel_id)
);

CREATE INDEX idx_subscriptions_channel ON subscriptions (channel_id);

