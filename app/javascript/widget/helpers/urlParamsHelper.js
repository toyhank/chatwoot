export const buildSearchParamsWithLocale = search => {
  // [TODO] for now this works, but we will need to find a way to get the locale from the root component
  const locale = window.WOOT_WIDGET.$root.$i18n.locale;
  const params = new URLSearchParams(search);
  params.append('locale', locale);

  return `?${params}`;
};

export const getLocale = (search = '') => {
  return new URLSearchParams(search).get('locale');
};

export const getUserParamsFromURL = (search = '') => {
  const params = new URLSearchParams(search);
  const identifier = params.get('identifier');
  const identifierHash = params.get('identifier_hash');
  const email = params.get('email');
  const name = params.get('name');
  const avatarUrl = params.get('avatar_url');
  const phoneNumber = params.get('phone_number');

  if (!identifier) {
    return null;
  }

  const user = {};
  if (identifierHash) user.identifier_hash = identifierHash;
  if (email) user.email = email;
  if (name) user.name = name;
  if (avatarUrl) user.avatar_url = avatarUrl;
  if (phoneNumber) user.phone_number = phoneNumber;

  return { identifier, user };
};

export const buildPopoutURL = ({
  origin,
  conversationCookie,
  websiteToken,
  locale,
}) => {
  const popoutUrl = new URL('/widget', origin);
  popoutUrl.searchParams.append('cw_conversation', conversationCookie);
  popoutUrl.searchParams.append('website_token', websiteToken);
  popoutUrl.searchParams.append('locale', locale);

  return popoutUrl.toString();
};
