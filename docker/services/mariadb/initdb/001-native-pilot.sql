CREATE TABLE IF NOT EXISTS users (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    country_code CHAR(2) NOT NULL,
    created_at DATETIME NOT NULL
);

INSERT INTO users (id, name, email, country_code, created_at) VALUES
(1, 'Benchmark User', 'benchmark@example.test', 'ID', '2026-01-01 00:00:00'),
(2, 'Alice Research', 'alice@example.test', 'ID', '2026-01-02 01:00:00'),
(3, 'Bob Study', 'bob@example.test', 'ID', '2026-01-03 02:00:00'),
(4, 'Carol Test', 'carol@example.test', 'ID', '2026-01-04 03:00:00'),
(5, 'Dave Metrics', 'dave@example.test', 'ID', '2026-01-05 04:00:00')
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    email = VALUES(email),
    country_code = VALUES(country_code),
    created_at = VALUES(created_at);

CREATE TABLE IF NOT EXISTS posts (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    is_published TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL,
    INDEX idx_posts_created (created_at),
    INDEX idx_posts_user (user_id)
);

INSERT INTO posts (id, user_id, title, body, is_published, created_at) VALUES
(1,  1, 'Benchmark Post 01',  'Lorem ipsum dolor sit amet, consectetur adipiscing elit.', 1, '2026-01-01 12:00:00'),
(2,  1, 'Benchmark Post 02',  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', 1, '2026-01-01 12:01:00'),
(3,  2, 'Benchmark Post 03',  'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris.', 1, '2026-01-01 12:02:00'),
(4,  2, 'Benchmark Post 04',  'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum.', 1, '2026-01-01 12:03:00'),
(5,  3, 'Benchmark Post 05',  'Excepteur sint occaecat cupidatat non proident, sunt in culpa qui.', 1, '2026-01-01 12:04:00'),
(6,  3, 'Benchmark Post 06',  'Officia deserunt mollit anim id est laborum.', 1, '2026-01-01 12:05:00'),
(7,  1, 'Benchmark Post 07',  'Sed ut perspiciatis unde omnis iste natus error sit voluptatem.', 1, '2026-01-01 12:06:00'),
(8,  4, 'Benchmark Post 08',  'Accusantium doloremque laudantium, totam rem aperiam, eaque ipsa.', 1, '2026-01-01 12:07:00'),
(9,  4, 'Benchmark Post 09',  'Quae ab illo inventore veritatis et quasi architecto beatae vitae.', 1, '2026-01-01 12:08:00'),
(10, 5, 'Benchmark Post 10',  'Dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas.', 1, '2026-01-01 12:09:00'),
(11, 5, 'Benchmark Post 11',  'Sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores.', 1, '2026-01-01 12:10:00'),
(12, 2, 'Benchmark Post 12',  'Eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est.', 1, '2026-01-01 12:11:00'),
(13, 3, 'Benchmark Post 13',  'Qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit.', 1, '2026-01-01 12:12:00'),
(14, 4, 'Benchmark Post 14',  'Sed quia non numquam eius modi tempora incidunt ut labore et dolore.', 1, '2026-01-01 12:13:00'),
(15, 5, 'Benchmark Post 15',  'Magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis.', 1, '2026-01-01 12:14:00'),
(16, 1, 'Benchmark Post 16',  'Nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut.', 1, '2026-01-01 12:15:00'),
(17, 2, 'Benchmark Post 17',  'Aliquid ex ea commodi consequatur? Quis autem vel eum iure.', 1, '2026-01-01 12:16:00'),
(18, 3, 'Benchmark Post 18',  'Reprehenderit qui in ea voluptate velit esse quam nihil molestiae.', 1, '2026-01-01 12:17:00'),
(19, 4, 'Benchmark Post 19',  'Consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla.', 1, '2026-01-01 12:18:00'),
(20, 5, 'Benchmark Post 20',  'Pariatur? At vero eos et accusamus et iusto odio dignissimos ducimus.', 1, '2026-01-01 12:19:00')
ON DUPLICATE KEY UPDATE
    title = VALUES(title),
    body = VALUES(body),
    is_published = VALUES(is_published),
    created_at = VALUES(created_at);
