export const standing = ({ version, published }) =>
  [ version ? `Version ${version}` : "No version yet",
    published ? `visitors run ${published}` : "nothing published" ].join(" · ")
